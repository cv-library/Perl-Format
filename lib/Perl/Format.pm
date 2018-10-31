package Perl::Format 0.001;

use strict;
use warnings;

use PPI::Token::Word;
use Scalar::Util 'refaddr';

my %scalar_ops;
@scalar_ops{qw{* x + - . == != += -= *=}} = ();

# Removes the element and any adjacent right whitespace.
my $delete = sub {
    my $siblings = ( my $elem = shift )->parent->{children};

    my %skip = ( refaddr $elem => undef );

    $skip{ refaddr $elem } = undef
        if ( $elem = $elem->next_sibling )
        && $elem->isa('PPI::Token::Whitespace');

    # Remove the elements from the parent's children array.
    @$siblings = grep !exists $skip{ refaddr $_ }, @$siblings;
};

my @rules = (
    # $foo{bar}->[123]->() → $foo{bar}[123]()
    [
        sub {
            exists $_[0]{_dereference}
                && $_[0]->previous_sibling->isa('PPI::Structure::Subscript');
        },
        $delete,
    ],
    # $foo{'bar'} → $foo{bar}
    [
        sub {
            my $elem = shift;

            return unless $elem->isa('PPI::Token::Quote');

            my $key = $elem->string;

            $key =~ /^-?\w+$/a
                && do { no strict; no warnings; $key eq eval "($key=>)[0]" }
                && $elem->parent
                && $elem->parent->isa('PPI::Statement::Expression')
                && $elem->parent->parent
                && $elem->parent->parent->isa('PPI::Structure::Subscript')
                && !$elem->snext_sibling
                && !$elem->sprevious_sibling;
        },
        sub {
            my $addr = refaddr( my $elem = shift );

            $_ = PPI::Token::Word->new( $elem->string )
                for grep $addr == refaddr $_, @{ $elem->parent->{children} };
        },
    ],
    # m!abc!s → /abc/s
    [
        sub {
            no warnings 'uninitialized';

            $_[0]->isa('PPI::Token::Regexp::Match')
                && $_[0]{operator} eq 'm'
                && !$_[0]{braced}
                && ( $_[0]{separator} eq '/' || $_[0]{content} !~ m(/) );
        },
        sub {
            my ( $pos, $size ) = @{ $_[0]{sections}[0] }{qw/position size/};

            # Replace delimiters.
            substr $_[0]{content}, $pos - 1,     1, '/';
            substr $_[0]{content}, $pos + $size, 1, '/';

            # Chop upto the first delimiter.
            substr $_[0]{content}, 0, $pos - 1, '';
        },
    ],
    # "foo" → 'foo'
    [
        sub {
            $_[0]->isa('PPI::Token::Quote::Double')
                && $_[0]{content} !~ /[\\\$\@']/
        },
        sub {
            $_[0]{content} = "'" . substr( $_[0]{content}, 1, -1 ) . "'";

            bless $_[0], 'PPI::Token::Quote::Single';
        },
    ],
    # foo( 1, 2, 3, ) → foo( 1, 2, 3 )
    [
        sub {
            $_[0]->isa('PPI::Structure::List')
                && @{ $_[0]{children} } > 1
                && $_[0]{children}[-1]->isa('PPI::Token::Whitespace')
                && $_[0]{children}[-1]{content} eq ' '
                && $_[0]{children}[-2]->isa('PPI::Statement::Expression')
                && $_[0]{children}[-2]{children}[-1]->isa('PPI::Token::Operator')
                && $_[0]{children}[-2]{children}[-1]{content} eq ',';
        },
        sub { $#{ $_[0]{children}[-2]{children} }-- },
    ],
    # 'foo' x/+/-/. scalar @bar → 'foo' x/+/-/. @bar
    [
        sub {
            my $elem = shift;

               $elem->isa('PPI::Token::Word')
            && $elem->{content} eq 'scalar'
            && ( $elem = $elem->sprevious_sibling )
            && $elem->isa('PPI::Token::Operator')
            && exists $scalar_ops{ $elem->{content} };
        },
        $delete,
    ],
    # $d->last_insert_id( undef, undef, undef, undef ) → $d->last_insert_id
    [
        sub {
            my $elem = shift;

               $elem->isa('PPI::Token::Word')
            && $elem->{content} eq 'last_insert_id'
            && ( $elem = $elem->next_sibling )
            && $elem->isa('PPI::Structure::List')
            # FIXME String matching is bloody hacky.
            && ( $elem->content eq '( (undef) x 4 )'
              || $elem->content eq '( undef, undef, undef, undef )'
            );
        },
        sub { $delete->( $_[0]->next_sibling ) },
    ],
);

sub run {
    my ( $class, $doc ) = @_;

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
            } else {
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
