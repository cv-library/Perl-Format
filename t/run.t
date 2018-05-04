use strict;
use warnings;

use List::Util 'pairs';
use Perl::Format;
use PPI::Document;
use Test::More;

for (<t/*.pl>) {
    my @tests = map s/^\s+|\s+$//gr, split /^#.*$/m,
        do { local ( @ARGV, $/ ) = $_; <> };

    for ( pairs @tests ) {
        my ( $from, $to ) = @$_;

        my $doc = PPI::Document->new(\$from);

        Perl::Format->run($doc);

        is $doc->serialize, $to, "$from → $to";
    }
}

done_testing;
