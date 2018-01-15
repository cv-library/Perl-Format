$foo{bar}
$foo{bar}

$foo{'bar'}
$foo{bar}

$foo{"bar"}
$foo{bar}

$foo{q{bar}}
$foo{bar}

$foo{qq{bar}}
$foo{bar}

$foo{'-1'}
$foo{-1}

$foo{'_1'}
$foo{_1}

$foo{'-bar'}
$foo{-bar}

# Leave these ones alone.

$foo{'a.b'}
$foo{'a.b'}

$foo{'1_'}
$foo{'1_'}
