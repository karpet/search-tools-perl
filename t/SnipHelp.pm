package SnipHelp;
use Test::More;
use strict;
use warnings;
use Data::Dump qw( dump );
use File::Slurp;
use Search::Tools::XML;
use Search::Tools::Snipper;
use Search::Tools::UTF8;

sub test {
    my ( $file, $q, $snipper_type ) = @_;
    use_ok('Search::Tools');
    use_ok('Search::Tools::Snipper');
    use_ok('Search::Tools::HiLiter');
    use_ok('Search::Tools::XML');
    ok( my $XML   = Search::Tools::XML->new, "new XML object" );
    ok( my $html  = read_file($file),        "read buf" );
    ok( my $plain = $XML->strip_html($html), "strip_html" );

    if ( $XML->looks_like_html($html) ) {
        cmp_ok( $html, 'ne', $plain, "strip_html ok" );
        if ( $XML->looks_like_html($plain) ) {
            fail("plain text has no html");
        }
        else {
            pass("plain text has no html");
        }
    }
    else {
        pass("strip_html skipped");
        pass("strip_html skipped");
    }
    ok( my $regex = Search::Tools->regexp( query => $q ), "new regex" );
    ok( my $snipper = Search::Tools::Snipper->new(
            query     => $regex,
            occur     => 1,
            context   => 25,
            max_chars => 190,
            type      => $snipper_type,    # make explicit
                                           #escape    => 1,
        ),
        "new snipper"
    );
    ok( my $hiliter = Search::Tools::HiLiter->new(
            query => $regex,
            tag   => "b",
            class => "x",
            tty   => $snipper->debug,
        ),
        "new hiliter"
    );

    ok( my $snip    = $snipper->snip($plain),  "snip plain" );
    ok( my $hilited = $hiliter->hilite($snip), "hilite" );

    return ( $snip, $hilited, $regex, $plain );
}

1;
