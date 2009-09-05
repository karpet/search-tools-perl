use strict;
use Test::More tests => 16;
use lib 't';
use SnipHelp;    # runs 14 tests

my $file  = 't/docs/linux-user-group.html';
my $query = qq/"linux user group"/;
my ( $snip, $hilited ) = SnipHelp::test( $file, $query );
is( $snip,
    qq{ ... Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape Linux User Group : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group ... },
    "snip"
);
is( $hilited,
    qq{ ... Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape <b class="x">Linux User Group</b> : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group ... },
    "hilited"
);
