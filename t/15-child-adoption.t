use strict;
use Test::More tests => 14;
use lib 't';
use SnipHelp;    # runs 12 tests

my $file  = 't/docs/child-adoption.html';
my $query = qq/child adoption/;
my ( $snip, $hilited, $regex, $buf ) = SnipHelp::test( $file, $query );
is( $snip,
    q{ ... I do not expect any well meaning and caring parent to display such a callous disregard for their child. The safest place to wait is at the entrance closest to the movies and Milky Lane, so why did they ... },
    "snip"
);
is( $hilited,
    q{ ... I do not expect any well meaning and caring parent to display such a callous disregard for their <b class="x">child</b>. The safest place to wait is at the entrance closest to the movies and Milky Lane, so why did they ... },
    "hilited"
);
