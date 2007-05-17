use Test::More tests => 14;

BEGIN
{
    use_ok('Search::Tools::Transliterate');
    use_ok('Search::Tools::UTF8');
}

use Encode;

ok(my $t = Search::Tools::Transliterate->new(ebit => 0), "new transliterator");

my $babel = do 't/quick_brown_babel.dmp';

for my $lang (sort keys %$babel)
{

    diag("$lang: $babel->{$lang}\n") if $ENV{PERL_TEST};
    ok(my $trans = $t->convert($babel->{$lang}), "transliterated");
    diag("transliteration: $trans") if $ENV{PERL_TEST};

}

# transliterate some latin1
my $latin1 = 'ÈÉÊÃ ¾ ´ ª æ';

ok(!eval { $t->convert($latin1); 1; },
    "successful failure - can't convert latin1: " . $@);

ok(my $utf8 = Encode::encode_utf8(Encode::decode('iso-8859-1', $latin1, 1)),
    "re-encode latin1 -> utf8");
ok(is_valid_utf8($utf8), "re-encode is valid: $utf8");
ok(my $trans_latin1 = $t->convert($utf8), "$utf8 transliterated");
diag("$utf8 -> $trans_latin1") if $ENV{PERL_TEST};

