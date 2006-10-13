use Test::More tests => 59;

use Carp;

use_ok('Search::Tools::RegExp');

my %q = (
    'the quick'                         => 'quick',         # stopwords
    'color:brown       fox'             => 'brown fox',     # fields
    '+jumped and +ran         -quickly' => 'jumped ran',    # booleans
    '"over the or lazy        and dog"' => 'over the or lazy and dog',  # phrase
    'foo* food bar' => 'foo* food bar',    # wildcard
    'foo foo*'      => 'foo*',             # unique wildcard
    'ªµº ÀÁÂÃÄÅÆ Ç ÈÉÊË ÌÍÎÏ ĞÑ ÒÓÔÕÖØ ÙÚÛÜ İŞ ß àáâãäåæ ç èéêë ìíîï ğ ñ òóôõöø ùúûü ışÿ'
      => 'ªµº ÀÁÂÃÄÅÆ Ç ÈÉÊË ÌÍÎÏ ĞÑ ÒÓÔÕÖØ ÙÚÛÜ İŞ ß àáâãäåæ ç èéêë ìíîï ğ ñ òóôõöø ùúûü ışÿ' # 8bit chars
);

ok(
    my $re =
      Search::Tools::RegExp->new(
                                 locale    => 'en_US.iso-8859-1',
                                 stopwords => 'the'
                                ),

    "re object"
  );

ok(my $kw = $re->build([keys %q]), "build re");

for my $w ($kw->keywords)
{
    my $r = $kw->re($w);

    # interesting. diag() doesn't pring utf-8 correctly but carp does.
    #diag($w);
    #carp $w;
    like($w, $r->plain, $w);
    like($w, $r->html,  $w);

    #diag($r->plain);

}
