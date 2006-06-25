use Test::More tests => 7;

use File::Slurp;

BEGIN { use_ok('Search::Tools::Snipper') }

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
                                  max_chars => length($text) - 1
                                 ),
    "snipper"
  );

ok(my $snip = $s->snip($text), "snip");
#diag($snip);

ok(length($snip) < $s->max_chars, "snip");
#diag($s->snipper_name);

$text = read_file('t/test.txt');

@q = qw(intramuralism maimedly sculpt);

ok(
    $s =
      Search::Tools::Snipper->new(
                                  query     => [@q],
                                  max_chars => length($text) - 1
                                 ),
    "new snipper"
  );

ok($snip = $s->snip($text), "new snip");
#diag($snip);
#diag($s->snipper_name);

ok(length($snip) < $s->max_chars, "more snip");

