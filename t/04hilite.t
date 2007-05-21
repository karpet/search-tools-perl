use Test::More tests => 18;

use File::Slurp;
use Data::Dumper;

use_ok('Search::Tools::HiLiter');
use_ok('Search::Tools::Snipper');

my $debug = $ENV{PERL_DEBUG} || 0;

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

ok(my $re = Search::Tools::RegExp->new(debug => $debug), "RE");
ok(
    my $h =
      Search::Tools::HiLiter->new(tty => $debug, query => $re->build(\@q)),
    "hiliter"
  );
ok(my $s = Search::Tools::Snipper->new(debug => $debug, query => $h->rekw),
    "snipper");

#diag( Dumper( $re ) );

ok(my $snip = $s->snip($text), "snip");

$debug and diag($snip);

#diag($s->snipper_name);
$debug and diag($s->count);

ok(my $l = $h->light($snip), "light");

$debug and diag($l);

# and again

$text = read_file('t/test.txt');

@q = qw(intramuralism maimedly sculpt);

ok($h = Search::Tools::HiLiter->new(tty => $debug, query => \@q),
    "new hiliter");
ok($s = Search::Tools::Snipper->new(debug => $debug, query => $h->rekw),
    "new snipper");

ok($snip = $s->snip($text), "new snip");

$debug and diag($snip);

#diag($s->snipper_name);
$debug and diag($s->count);

ok($l = $h->light($snip), "new light");

$debug and diag($l);

# now just a raw html file without snipping

ok(
    $h = Search::Tools::HiLiter->new(
        query =>
          q/o'reilly the quick brown fox* jumped! "jumped over the too lazy"/,

        #tty       => 1,
        #no_html   => 1,
        stopwords => 'the',
        tty     => $debug,
                                    ),
    "nosnip hiliter"
  );
$text = read_file('t/test.html');
ok($l = $h->light($text), "nosnip light");

$debug and diag($l);

# test long multibyte UTF8
$text = read_file('t/john1_gr.txt');
@q = ("αμην");    # greek

ok($s = Search::Tools::Snipper->new(query => [@q], escape => 0),    "greek snipper");
ok($h = Search::Tools::HiLiter->new(query => [@q], tty => $debug),  "greek hiliter");
ok($snip = $s->snip($text), "greek snip");
is($s->count, 1, "1 greek snip");
ok($l = $h->light($snip),   "light greek");
$debug and diag($l);