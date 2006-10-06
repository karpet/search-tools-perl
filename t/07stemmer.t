use Test::More tests => 5;

BEGIN { use_ok('Search::Tools::RegExp') }

my %q = (
    'the apples' => 'apple',    # stopwords

        );

ok(
    my $re = Search::Tools::RegExp->new(
        lang => 'en_us',

        stopwords => 'the brown',
        stemmer   => sub {
            my $w = $_[1];
            $w =~ s/s$//;
            return $w;

        }
    ),

    "re object"
  );

ok(my $kw = $re->build([keys %q]), "build re");

for my $w ($kw->keywords)
{
    my $r = $kw->re($w);

    my $plain = $r->plain;
    my $html  = $r->html;

    like($w, qr{^$plain$}x, "$w plain");
    like($w, qr{^$html$}x,  "$w html");

    #diag($plain);
    #diag($html);
}
