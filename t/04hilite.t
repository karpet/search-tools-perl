use Test::More tests => 13;

use File::Slurp;
use Data::Dumper;

BEGIN
{

    use_ok('Search::Tools::HiLiter');
    use_ok('Search::Tools::Snipper');

}

my $text = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
EOF

my @q = ('squiggle', 'type', 'course', '"human events"');

ok(my $re = Search::Tools::RegExp->new(), "RE");
ok(my $h = Search::Tools::HiLiter->new(query => $re->build(\@q)), "hiliter");
ok(my $s = Search::Tools::Snipper->new(query => $h->rekw), "snipper");

#diag( Dumper( $re ) );

ok(my $snip = $s->snip($text), "snip");

#diag($snip);
#diag($s->snipper_name);
#diag($s->count);

ok(my $l = $h->light($snip), "light");

#diag($l);

# and again

$text = read_file('t/test.txt');

@q = qw(intramuralism maimedly sculpt);

ok($h = Search::Tools::HiLiter->new(query => \@q), "new hiliter");
ok($s = Search::Tools::Snipper->new(query => $h->rekw), "new snipper");

ok($snip = $s->snip($text), "new snip");

#diag($snip);
#diag($s->snipper_name);
#diag($s->count);

ok($l = $h->light($snip), "new light");

#diag($l);

# now just a raw html file without snipping

ok(
    $h =
      Search::Tools::HiLiter->new(
          query =>
            q/o'reilly the quick brown fox* jumped! "jumped over the too lazy"/,
          #tty       => 1,
          #no_html   => 1,
          stopwords => 'the'
      ),
    "nosnip hiliter"
  );
$text = read_file('t/test.html');
ok($l = $h->light($text), "nosnip light");
#diag($l);

