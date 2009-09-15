use strict;
use Test::More tests => 17;
use lib 't';
use SnipHelp;    # runs 15 tests

my $file = 't/docs/findaprofessional.txt';
my $q    = qq/findaprofessional/;
my ( $snip, $hilited, $query, $buf ) = SnipHelp::test( $file, $q );
is( $snip,
    q{ ... astute members of the South African public needing professional services. Enquiries: info@findaprofessional.co.za "The best executive is the one who has the sense ... },
    "snip"
);
is( $hilited,
    q{ ... astute members of the South African public needing professional services. Enquiries: info@<b class="x">findaprofessional</b>.co.za "The best executive is the one who has the sense ... },
    "hilited"
);
