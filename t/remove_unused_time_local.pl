use Time::Local;

my $time = timegm $s, $m, $h, $d, $M, $y;

#

use Time::Local;

my $time = timegm $s, $m, $h, $d, $M, $y;

##

use Time::Local;

my $time = timelocal(@time);

#

use Time::Local;

my $time = timelocal(@time);

##

use Time::Local;

my $time = Time::Local::timegm_nocheck $s, $m, $h, $d, $M, $y;

#

use Time::Local;

my $time = Time::Local::timegm_nocheck $s, $m, $h, $d, $M, $y;

##

use Time::Local;

my $time = Time::Local::timelocal_nocheck(@time);

#

use Time::Local;

my $time = Time::Local::timelocal_nocheck(@time);

##

use Time::Local;

my $time = foo();

#

my $time = foo();
