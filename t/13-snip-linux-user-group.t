use strict;
use Test::More tests => 17;
use lib 't';
use SnipHelp;    # runs 15 tests

my $file = 't/docs/linux-user-group.html';
my $q    = qq/"linux user group"/;
my ( $snip, $hilited, $query ) = SnipHelp::test( $file, $q );
is( $snip,
    qq{ ... Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape Linux User Group : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group ... },
    "snip"
);
is( $hilited,
    qq{ ... Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape <b class="x">Linux User Group</b> : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group ... },
    "hilited"
);
