use Test::More tests => 13;

BEGIN { use_ok('Search::Tools::RegExp') }

my %q = (
    'the quick'             => 'quick',        # stopwords
    '"the quick brown fox"' => 'quick fox',    # phrase stopwords

        );

ok(
    my $re =
      Search::Tools::RegExp->new(
                                 lang    => 'en_us',
                                 stopwords => 'the brown'
                                ),

    "re object"
  );

ok(my $kw = $re->build([keys %q]), "build re");

for my $w ($kw->keywords)
{
    my $r     = $kw->re($w);
    my $plain = $r->plain;
    my $html  = $r->html;

    like($w, qr{^$plain$}, $w);
    like($w, qr{^$html$},  $w);

    #diag($plain);

}

ok(
    $re =
      Search::Tools::RegExp->new(
                                 lang    => 'en_us',
                                 stopwords => [qw(the brown)]
                                ),

    "re object"
  );

ok($kw = $re->build([keys %q]), "build re");

for my $w ($kw->keywords)
{
    my $r     = $kw->re($w);
    my $plain = $r->plain;
    my $html  = $r->html;

    like($w, qr{^$plain$}, $w);
    like($w, qr{^$html$},  $w);

    #diag($plain);

}
