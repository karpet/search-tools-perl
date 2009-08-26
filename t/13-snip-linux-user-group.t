use strict;
use Test::More tests => 14;
use lib 't';
use SnipHelp;    # runs 12 tests

my $file  = 't/docs/linux-user-group.html';
my $query = qq/"linux user group"/;
my ( $snip, $hilited ) = SnipHelp::test( $file, $query );
is( $snip,
    qq{ ... The Universal Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape Linux User Group : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group Comics ... },
    "snip"
);
is( $hilited,
    qq{ ... The Universal Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape <b class="x">Linux User Group</b> : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group Comics ... },
    "hilited"
);
