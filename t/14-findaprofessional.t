use strict;
use Test::More tests => 16;
use lib 't';
use SnipHelp;    # runs 14 tests

my $file  = 't/docs/findaprofessional.txt';
my $query = qq/findaprofessional/;
my ( $snip, $hilited, $regex, $buf ) = SnipHelp::test( $file, $query );
is( $snip,
    q{ ... astute members of the South African public needing professional services. Enquiries: info@findaprofessional.co.za "The best executive is the one who has the sense ... },
    "snip"
);
is( $hilited,
    q{ ... astute members of the South African public needing professional services. Enquiries: info@<b class="x">findaprofessional</b>.co.za "The best executive is the one who has the sense ... },
    "hilited"
);
