#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;

use Search::Tools::XML;
my $utils = 'Search::Tools::XML';

my $data1 = {
    foo   => 'bar',
    array => [
        'one' => 1,
        'two' => 2,
    ],
    hash => {
        three => 3,
        four  => 4,
    },
};

ok( my $data1_xml = $utils->perl_to_xml( $data1, 'data1' ), "data1 to xml" );
like( $data1_xml, qr(<three>3</three>), "data1 xml" );

#diag( $utils->tidy($data1_xml) );

my $data2 = {
    arrays => [
        {   two   => 2,
            three => 3,
        },
        {   four => 4,
            five => 5,
        },
        {   foos => [
                {   depth => 2,
                    more  => 'here',
                }
            ],
        }

    ],
};

# exercise $strip_plural
ok( my $data2_xml = $utils->perl_to_xml( $data2, 'data2', 1 ),
    "data2 to xml" );

like( $data2_xml, qr(<arrays count="3">),       "data2 xml" );
like( $data2_xml, qr(<foos count="1">.*?<foo>), "data2 xml" );
