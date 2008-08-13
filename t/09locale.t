use Test::More tests => 2;

use Search::Tools::Keywords;

BEGIN
{
    use POSIX qw(locale_h);
    use locale;
    setlocale(LC_ALL, 'en_US.UTF-8');
}

ok(my $kw = Search::Tools::Keywords->new(), "new keywords");

diag($kw->locale);

SKIP: {

    my $locale = setlocale( LC_CTYPE );

    skip "UTF-8 charset not supported", 1 if $locale ne 'en_US.UTF-8';

    is($kw->charset, 'UTF-8', "UTF-8 charset");
}

