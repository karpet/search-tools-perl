use strict;
use Test::More tests => 14;
use lib 't';
use SnipHelp;    # runs 12 tests

my $file  = 't/docs/findaprofessional.txt';
my $query = qq/findaprofessional/;
my ( $snip, $hilited, $regex, $buf ) = SnipHelp::test( $file, $query );
is( $snip,
    q{ ... for astute members of the South African public needing professional services. Enquiries: info@findaprofessional.co.za "The best executive is the one who has the sense to pick good people to do what he wants done" ... },
    "snip"
);
is( $hilited,
    q{ ... for astute members of the South African public needing professional services. Enquiries: info@<b class="x">findaprofessional</b>.co.za "The best executive is the one who has the sense to pick good people to do what he wants done" ... },
    "hilited"
);
