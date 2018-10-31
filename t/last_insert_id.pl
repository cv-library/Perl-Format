$dbh->last_insert_id;
#
$dbh->last_insert_id;

##

$dbh->last_insert_id( undef, undef, undef, undef );
#
$dbh->last_insert_id;

##

$dbh->last_insert_id( (undef) x 4 );
#
$dbh->last_insert_id;

## Leave these ones alone.

$dbh->last_insert_id();
#
$dbh->last_insert_id();

##

$dbh->last_insert_id( $catalog, $schema, $table, $field );
#
$dbh->last_insert_id( $catalog, $schema, $table, $field );

##

$dbh->last_insert_id( $catalog, $schema, $table, $field, \%attr );
#
$dbh->last_insert_id( $catalog, $schema, $table, $field, \%attr );
