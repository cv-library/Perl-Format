package Perl::Format 0.001;

use strict;
use warnings;

use PPI::Token::Word;
use Scalar::Util 'refaddr';

my @rules = (
    # $foo{bar}->[123]->() → $foo{bar}[123]()
    [
        sub {
            exists $_[0]{_dereference}
                && $_[0]->previous_sibling->isa('PPI::Structure::Subscript');
        },
        sub {
            my $addr = refaddr( my $elem = shift );

            my $siblings = $elem->parent->{children};

            # Remove the arrow from the parent's children array.
            @$siblings = grep $addr != refaddr $_, @$siblings;
        },
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
    # m/abc/ → /abc/
    [
        sub {
            my $elem = shift;

            no warnings 'uninitialized';

            $elem->isa('PPI::Token::Regexp::Match')
                && $elem->{operator} eq 'm'
                && $elem->{separator} eq '/';
        },
        sub { $_[0]{content} =~ s/^m// },
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
    ]
);

sub run {
    my ( $class, $doc ) = @_;

    my $changed;

    for (@rules) {
        my ( $find, $rewrite ) = @$_;

        my ( @queue, @elems ) = $doc;

        while ( my $elem = shift @queue ) {
                push @elems, $elem if $find->($elem);

                # Skip if the element doesn't have any children.
                next unless $elem->isa('PPI::Node');

                # Add the children to the head of the queue.
                if ( $elem->isa('PPI::Structure') ) {
                        unshift @queue,
                            $elem->finish || (),
                            $elem->children,
                            $elem->start || ();
                } else {
                        unshift @queue, $elem->children;
                }
        }

        $changed ||= @elems;

        $rewrite->($_) for @elems;
    }

    $changed;
}
