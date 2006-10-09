use Test::More tests => 2;

use Search::Tools::Keywords;
use POSIX qw(locale_h);
use locale;

BEGIN
{
    setlocale(LC_CTYPE, 'en_US.UTF-8');
}

ok(my $kw = Search::Tools::Keywords->new(), "new keywords");

diag($kw->locale);

is($kw->charset, 'UTF-8', "UTF-8 charset");
