use Test::More tests => 14;

use File::Slurp;

use_ok('Search::Tools::Snipper');
use_ok('Search::Tools::UTF8');

my $debug = $ENV{PERL_DEBUG} || 0;

# easy ascii snip
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

ok(
    my $s =
      Search::Tools::Snipper->new(
                                  query     => [@q],
                                  max_chars => length($text) - 1,
                                 # debug => 1
                                 ),
    "snipper"
  );

ok(my $snip = $s->snip($text), "simple snip");
$debug and diag(join(" ", @q) . ": $snip");
is($s->count, 2,    "2 simple snips");

# longer snip, still ascii
$text = read_file('t/test.txt');
@q    = qw(intramuralism maimedly sculpt);

ok(
    $s =
      Search::Tools::Snipper->new(
                                  query     => [@q],
                                  max_chars => length($text) - 1
                                 ),
    "new snipper"
  );

ok($snip = $s->snip($text), "long ascii file snip");
$debug and diag(join(" ", @q) . ": $snip");
is($s->count, 3, "three snips");

# test long multibyte UTF8
$text = read_file('t/john1_gr.txt');
@q = ("αμην");    # greek
ok($s = Search::Tools::Snipper->new(query => [@q], escape => 0));
ok($snip = $s->snip($text), "greek snip");
$debug and diag(join(" ", @q) . ": $snip");
is($s->count, 1, "1 greek snip");



# test snip of raw markup
$text = read_file('t/test.html');
@q = qw( jumped fox );
ok($s = Search::Tools::Snipper->new(query => [@q], escape => 0));
ok($snip = $s->snip($text), "html snip");
$debug and diag(join(" ", @q) . ": $snip");
is($s->count, 5,  "html snip count = 5");
