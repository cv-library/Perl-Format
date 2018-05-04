$foo{bar}
#
$foo{bar}

##

$foo{'bar'}
#
$foo{bar}

##

$foo{"bar"}
#
$foo{bar}

##

$foo{q{bar}}
#
$foo{bar}

##

$foo{qq{bar}}
#
$foo{bar}

##

$foo{'-1'}
#
$foo{-1}

##

$foo{'_1'}
#
$foo{_1}

##

$foo{'-bar'}
#
$foo{-bar}

## Keys that look like builtins are fine.

$foo{'print'}
#
$foo{print}

## Leave these ones alone.

$foo{'+bar'}
#
$foo{'+bar'}

##

$foo{'a.b'}
#
$foo{'a.b'}

##

$foo{'1_'}
#
$foo{'1_'}

##

$foo{'24HR'}
#
$foo{'24HR'}

##

$foo{ 'bar' . baz() }
#
$foo{ 'bar' . baz() }

##

@foo{ 'bar', 'baz' }
#
@foo{ 'bar', 'baz' }

##

@$foo{ 'bar', 'baz' }
#
@$foo{ 'bar', 'baz' }
