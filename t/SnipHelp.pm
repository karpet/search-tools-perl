package SnipHelp;
use Test::More;
use strict;
use warnings;
use Data::Dump qw( dump );
use File::Slurp;

sub test {
    my ( $file, $q ) = @_;
    use_ok('Search::Tools');
    use_ok('Search::Tools::Snipper');
    use_ok('Search::Tools::HiLiter');
    use_ok('Search::Tools::XML');
    ok( my $html  = read_file($file),        "read buf" );
    ok( my $xml   = Search::Tools::XML->new, "new xml object" );
    ok( my $plain = $xml->strip_html($html), "strip_html" );
    ok( my $regex = Search::Tools->regexp( query => $q ), "new regex" );
    ok( my $snipper = Search::Tools::Snipper->new(
            query     => $regex,
            occur     => 1,
            context   => 25,
            max_chars => 190,
            type      => 're',    # make explicit
        ),
        "new snipper"
    );
    ok( my $hiliter = Search::Tools::HiLiter->new(
            query => $regex,
            tag   => "b",
            class => "x",
        ),
        "new hiliter"
    );

    ok( my $snip    = $snipper->snip($plain),  "snip plain" );
    ok( my $hilited = $hiliter->hilite($snip), "hilite" );

    return ( $snip, $hilited, $regex, $plain );
}

1;
