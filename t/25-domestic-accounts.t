use strict;
use Search::Tools;
use Test::More tests => 5;
use File::Slurp;
use Data::Dump qw( dump );

ok( my $snipper = Search::Tools->snipper(
        query        => q(+domestic +accounts),
        occur        => 1,
        context      => 25,
        max_chars    => 190,
        as_sentences => 1,
    ),
    "create new snipper"
);

#dump( $hiliter->query );

ok( my $buf  = read_file('t/docs/domestic-accounts.html'), "read buf" );
ok( $buf     = Search::Tools::XML->strip_markup($buf),     "strip markup" );
ok( my $snip = $snipper->snip($buf),                       'snip buf' );

#diag($snip);
is( $snip,
    q( ... Over a number of years, municipal accounts ol some domestic consumers that do not qualify for free basic services in terms of Council's Assistance to the ... ),
    "got snip"
);
