use strict;
use Test::More tests => 16;
use lib 't';
use SnipHelp;    # runs 14 tests

my $file  = 't/docs/child-adoption.html';
my $query = qq/child adoption/;
my ( $snip, $hilited, $regex, $buf ) = SnipHelp::test( $file, $query );
is( $snip,
    q{ ... meaning and caring parent to display such a callous disregard for their child. The safest place to wait is at the entrance closest to the ... },
    "snip"
);
is( $hilited,
    q{ ... meaning and caring parent to display such a callous disregard for their <b class="x">child</b>. The safest place to wait is at the entrance closest to the ... },
    "hilited"
);
