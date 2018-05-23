my $foo = 123 * scalar @baz;
#
my $foo = 123 * @baz;

##

my $foo = 'bar' x scalar @baz;
#
my $foo = 'bar' x @baz;

##

my @foo = ('bar') x scalar @baz;
#
my @foo = ('bar') x @baz;

##

my $foo = 'bar' . scalar @baz;
#
my $foo = 'bar' . @baz;

##

my $foo = 123 + scalar(@baz);
#
my $foo = 123 + (@baz);

##

my $foo = 123 - scalar $bar->baz;
#
my $foo = 123 - $bar->baz;

##

if ( 123 == scalar @bar ) {}
#
if ( 123 == @bar ) {}

##

if ( 123 != scalar @bar ) {}
#
if ( 123 != @bar ) {}

##

$foo += scalar @bar;
#
$foo += @bar;

##

$foo -= scalar @bar;
#
$foo -= @bar;

##

$foo *= scalar @bar;
#
$foo *= @bar;

## Contrived but would change output if the parens were lost.

my $foo = 'bar' . scalar( 1 + 1 );
#
my $foo = 'bar' . ( 1 + 1 );

## Leave these ones alone.

my @foo = scalar @bar;
#
my @foo = scalar @bar;
