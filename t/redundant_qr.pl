"foo" =~ qr/foo/x
#
'foo' =~ /foo/x

##

$foo !~ qr{bar}
#
$foo !~ m{bar}

##

foo() ~~ qr!bar!s
#
foo() ~~ /bar/s

## Leave these ones alone.

$foo = qr/bar/
#
$foo = qr/bar/
