# Perl-Format [![Travis](https://travis-ci.org/cv-library/Perl-Format.svg)](https://travis-ci.org/cv-library/Perl-Format) [![Coveralls](https://coveralls.io/repos/github/cv-library/Perl-Format/badge.svg)](https://coveralls.io/github/cv-library/Perl-Format)

## Prefer Slash Regex Delimiters

### Before
```perl
m!foo!;
m/bar/g;
m(baz/qux);
```

### After
```perl
/foo/;
/bar/g;
m(baz/qux);
```

## Remove Useless Scalar

### Before
```perl
my $foo = scalar @foo;
if ( scalar @bar ) { ... }
print scalar @baz;
```

### After
```perl
my $foo = @foo;
if (@bar) { ... }
print scalar @baz;
```
