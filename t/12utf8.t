use Test::More tests => 21;

BEGIN { use_ok('Search::Tools::UTF8') }

use Data::Dump qw( dump );

my $latin1 = '»… √ æ ¥ ™ Ê';

ok(!is_valid_utf8($latin1),   "latin1 is not utf8");
ok(!is_ascii($latin1),        "latin1 is not ascii");
ok(!is_flagged_utf8($latin1), "latin1 is not flagged utf8");
ok(is_latin1($latin1),        "latin1 correctly identified");
ok(is_sane_utf8($latin1),
    "latin1 is sane utf8 - doesn't claim to be utf8 and doesn't look like it");

# now break some stuff
my $nonsense = 'Ê ascii „Åì';  # 1st byte is latin1, last 3 bytes are valid utf8

#diag("nonsense = " . dump( $nonsense ));

ok(!is_valid_utf8($nonsense), "nonsense is not utf8");
ok(!is_ascii($nonsense),      "nonsense is not ascii");
ok(!is_latin1($nonsense),     "nonsense is not latin1");
is(find_bad_utf8($nonsense),   $nonsense, "find_bad_utf8");
is(find_bad_ascii($nonsense),  1,         "find_bad_ascii");
is(find_bad_latin1($nonsense), 10,        "find_bad_latin1");

my $ambiguous = "this string is ambiguous \x{d9}\x{a6}";

#diag("ambiguous = " . dump( $ambiguous ));

ok(is_valid_utf8($ambiguous),           "is_valid_utf8 ambiguous");
ok(is_latin1($ambiguous),               "is_latin1 ambiguous");
ok(!defined(find_bad_utf8($ambiguous)), "find_bad_utf8 ambiguous");
is(find_bad_latin1($ambiguous), -1, "find_bad_latin1 ambiguous");

my $moreamb   = "this string should break is_latin1 \x{c3}\x{81}";

#diag("moreamb = " . dump( $moreamb ) );

ok(is_valid_utf8($moreamb),             "is_valid_utf8 moreamb");
ok(!is_latin1($moreamb),                "!is_latin1 moreamb");
ok(!defined(find_bad_utf8($moreamb)),   "find_bad_utf8 moreamb");
is(find_bad_latin1_report($moreamb), 37, "find_bad_latin1_report moreamb");

ok(!defined(find_bad_utf8('PC')),	"find_bad_utf8 allows ascii");
