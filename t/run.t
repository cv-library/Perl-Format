use List::Util 'pairs';
use Perl::Format;
use PPI::Document;
use Test2::V0;

for (<t/*.pl>) {
    chomp( my @tests = grep $_ ne $/ && !/^#/, do { local @ARGV = $_; <> } );

    for ( pairs @tests ) {
        my ( $from, $to ) = @$_;

        my $doc = PPI::Document->new(\$from);

        use Data::Dumper;
        #warn Dumper $doc;

        Perl::Format->run($doc);

        is $doc->serialize, $to, "$from → $to";
    }
}

done_testing;
