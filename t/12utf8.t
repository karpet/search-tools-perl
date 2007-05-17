use Test::More tests => 6;

BEGIN { use_ok('Search::Tools::UTF8') }

my $latin1 = '»… √ æ ¥ ™ Ê';

ok(!is_valid_utf8($latin1),   "latin1 is not utf8");
ok(!is_ascii($latin1),        "latin1 is not ascii");
ok(!is_flagged_utf8($latin1), "latin1 is not flagged utf8");
ok(is_latin1($latin1),        "latin1 correctly identified");
ok(is_sane_utf8($latin1),
    "latin1 is sane utf8 - doesn't claim to be utf8 and doesn't look like it");

