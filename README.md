# Perl::Format [![Travis](https://travis-ci.org/cv-library/Perl-Format.svg)](https://travis-ci.org/cv-library/Perl-Format) [![Coveralls](https://coveralls.io/repos/github/cv-library/Perl-Format/badge.svg)](https://coveralls.io/github/cv-library/Perl-Format)

## Rules

### last_insert_id
Remove redundant undefs from DBI's last_insert_id, asumes DBI 1.642+.

#### Before
```perl
$dbh->last_insert_id( undef, undef, undef, undef );
$dbh->last_insert_id( (undef) x 4 );
$dbh->last_insert_id( $catalog, $schema, $table, $field );
```

#### After
```perl
$dbh->last_insert_id;
$dbh->last_insert_id;
$dbh->last_insert_id( $catalog, $schema, $table, $field );
```

### redundant_scalar
Remove redundant scalar operators where the expression is already in scalar context.

#### Before
```perl
my $foo = scalar @foo;
if ( scalar @bar ) { ... }
print scalar @baz;
```

#### After
```perl
my $foo = @foo;
if (@bar) { ... }
print scalar @baz;
```

### slash_regexes
Rewrite regexes to use forward slash as the delimiter and drop the redundant `m`.

#### Before
```perl
m!foo!;
m/bar/g;
m(baz/qux);
```

#### After
```perl
/foo/;
/bar/g;
m(baz/qux);
```
