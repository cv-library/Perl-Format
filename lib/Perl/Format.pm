package Perl::Format 0.001;

use feature 'signatures';
use strict;
use warnings;
no warnings 'experimental';

use PPI::Token::Word;
use Scalar::Util 'refaddr';

my %scalar_ops;
@scalar_ops{qw{* x + - . == != += -= *=}} = ();

# Removes the element and any adjacent right whitespace.
my $delete = sub ($e) {
    my $siblings = $e->parent->{children};

    my %skip = ( refaddr $e => undef );

    $skip{ refaddr $e } = undef
        if ( $e = $e->next_sibling ) && $e->isa('PPI::Token::Whitespace');

    # Remove the elements from the parent's children array.
    @$siblings = grep !exists $skip{ refaddr $_ }, @$siblings;
};

my @rules = (
    # $foo{bar}->[123]->() → $foo{bar}[123]()
    [   sub ($e) {
            exists $e->{_dereference}
                && $e->previous_sibling->isa('PPI::Structure::Subscript');
        },
        $delete,
    ],
    # $foo{'bar'} → $foo{bar}
    [   sub ($e) {
            return unless $e->isa('PPI::Token::Quote');

            my $key = $e->string;

            return $key =~ /^-?\w+$/a
                && do { no strict; no warnings; $key eq eval "($key=>)[0]" }
                && $e->parent
                && $e->parent->isa('PPI::Statement::Expression')
                && $e->parent->parent
                && $e->parent->parent->isa('PPI::Structure::Subscript')
                && !$e->snext_sibling
                && !$e->sprevious_sibling;
        },
        sub ($e) {
            my $addr = refaddr $e;

            $_ = PPI::Token::Word->new( $e->string )
                for grep $addr == refaddr $_, @{ $e->parent->{children} };
        },
    ],
    # =~ qr/abc/ → =~ m/abc/
    [   sub ($e) {
            return $e->isa('PPI::Token::QuoteLike::Regexp')
                && ( $e = $e->sprevious_sibling )
                && $e->isa('PPI::Token::Operator')
                && $e->{content} =~ /^[!=~]~$/;
        },
        sub ($e) {
            bless $e, 'PPI::Token::Regexp::Match';

            $e->{content} =~ s/^qr/m/;
            $e->{operator} = 'm';
            $e->{sections}[0]{position}--;
        },
    ],
    # m!abc!s → /abc/s
    [   sub ($e) {
            no warnings 'uninitialized';

            return $e->isa('PPI::Token::Regexp::Match')
                && $e->{operator} eq 'm'
                && !$e->{braced}
                && ( $e->{separator} eq '/' || $e->{content} !~ m(/) );
        },
        sub ($e) {
            my ( $pos, $size ) = $e->{sections}[0]->@{qw/position size/};

            # Replace delimiters.
            substr $e->{content}, $pos - 1, 1, '/';
            substr $e->{content}, $pos + $size, 1, '/';

            # Chop upto the first delimiter.
            substr $e->{content}, 0, $pos - 1, '';
        },
    ],
    # "foo" → 'foo'
    [   sub ($e) {
            $e->isa('PPI::Token::Quote::Double') && $e->{content} !~ /[\\\$\@']/;
        },
        sub ($e) {
            bless $_[0], 'PPI::Token::Quote::Single';

            $e->{content} = "'" . substr( $e->{content}, 1, -1 ) . "'";
        },
    ],
    # foo( 1, 2, 3, ) → foo( 1, 2, 3 )
    [   sub ($e) {
            return $e->isa('PPI::Structure::List')
                && @{ $e->{children} } > 1
                && $e->{children}[-1]->isa('PPI::Token::Whitespace')
                && $e->{children}[-1]{content} eq ' '
                && $e->{children}[-2]->isa('PPI::Statement::Expression')
                && $e->{children}[-2]{children}[-1]->isa('PPI::Token::Operator')
                && $e->{children}[-2]{children}[-1]{content} eq ',';
        },
        sub { $#{ $_[0]{children}[-2]{children} }-- },
    ],
    # 'foo' x/+/-/. scalar @bar → 'foo' x/+/-/. @bar
    [   sub ($e) {
            return $e->isa('PPI::Token::Word')
                && $e->{content} eq 'scalar'
                && ( $e = $e->sprevious_sibling )
                && $e->isa('PPI::Token::Operator')
                && exists $scalar_ops{ $e->{content} };
        },
        $delete,
    ],
    # $d->last_insert_id( undef, undef, undef, undef ) → $d->last_insert_id
    [   sub ($e) {
            return $e->isa('PPI::Token::Word')
                && $e->{content} eq 'last_insert_id'
                && ( $e = $e->next_sibling )
                && $e->isa('PPI::Structure::List')
                # FIXME String matching is bloody hacky.
                && ( $e->content eq '( (undef) x 4 )'
                || $e->content eq '( undef, undef, undef, undef )' );
        },
        sub ($e) { $delete->( $e->next_sibling ) },
    ],
);

sub run ( $class, $doc ) {
    my ( $changed, $time_local );

    for (@rules) {
        my ( $find, $rewrite ) = @$_;

        my ( @q, @rewrite ) = $doc;

        while ( my $e = shift @q ) {
            push @rewrite, $e if $find->($e);

            $time_local = $e
                if $e->isa('PPI::Statement::Include')
                && $e->{children}[0]{content} eq 'use'
                && $e->{children}[2]{content} eq 'Time::Local';

            undef $time_local
                if $time_local
                && $e->isa('PPI::Token::Word')
                && $e->{content} =~ /^(Time::Local::)?time(gm|local)?(_nocheck)?$/n;

            # Skip if the element doesn't have any children.
            next unless $e->isa('PPI::Node');

            # Add the children to the head of the queue.
            if ( $e->isa('PPI::Structure') ) {
                unshift @q, $e->finish || (), $e->children, $e->start || ();
            }
            else {
                unshift @q, $e->children;
            }
        }

        $changed ||= @rewrite;

        $rewrite->($_) for @rewrite;
    }

    if ($time_local) {
        my $addr = refaddr $time_local;

        my $siblings = $time_local->parent->{children};

        # Remove the use line from the parent's children array.
        @$siblings = grep $addr != refaddr $_, @$siblings;

        $changed = 1;
    }

    $changed;
}
