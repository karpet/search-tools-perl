use Test::More tests => 2;

use Search::Tools::Keywords;

BEGIN {
    use POSIX qw(locale_h);
    use locale;
    setlocale( LC_ALL, 'en_US.UTF-8' );
}

ok( my $kw = Search::Tools::Keywords->new(), "new keywords" );

diag( 'queryparser (keywords) locale: ' . $kw->locale );

SKIP: {

    my $locale_ctype = setlocale(LC_CTYPE);
    diag("setlocale(LC_CTYPE) = $locale_ctype");
    my $locale_all = setlocale(LC_ALL);
    diag("setlocale(LC_ALL) = $locale_all");

    skip "UTF-8 charset not supported", 1 if $locale_ctype ne 'en_US.UTF-8';

    is( uc($kw->charset), 'UTF-8', "UTF-8 charset" );
}

