use Test::More tests => 16;

BEGIN { use_ok('Search::Tools::Transliterate') }

use Encode;

ok(my $t = Search::Tools::Transliterate->new(ebit=>0), "new transliterator");

my $babel = do 't/quick_brown_babel.dmp';

for my $lang (sort keys %$babel)
{

    diag("$lang: $babel->{$lang}\n") if $ENV{PERL_TEST};
    ok(my $trans = $t->convert($babel->{$lang}), "transliterated");
    diag("transliteration: $trans") if $ENV{PERL_TEST};

}

# those should all work above
# now make some that should fail

my $latin1 = 'ÈÉÊÃ ¾ ´ ª æ';

ok(!$t->is_valid_utf8($latin1),   "latin1 is not utf8");
ok(!$t->is_ascii($latin1),        "latin1 is not ascii");
ok(!$t->is_flagged_utf8($latin1), "latin1 is not flagged utf8");
ok($t->is_sane_utf8($latin1),
    "latin1 is sane utf8 - doesn't claim to be utf8 and doesn't look like it");

# and finally, transliterate our latin1

ok(!eval { $t->convert($latin1); 1; }, "can't convert latin1");

ok(my $utf8 = Encode::encode_utf8(Encode::decode('iso-8859-1', $latin1, 1)),
    "re-encode latin1 -> utf8");
ok(my $trans_latin1 = $t->convert($utf8), "$utf8 transliterated");
diag("$utf8 -> $trans_latin1") if $ENV{PERL_TEST};

