use strict;
use Test::More tests => 11;
use Data::Dump qw( dump );
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

my @q = ( 'squiggle', 'type', 'course', '"human events"' );

ok( my $s = Search::Tools::Snipper->new(
        query     => [@q],
        max_chars => length($text) - 1,
    ),
    "snipper"
);

ok( my $snip = $s->snip($text), "snip" );

diag($snip);
diag($s->type_used);

ok( length($snip) < $s->max_chars, "max_chars" );

#diag($s->type_used);

$text = read_file('t/docs/test.txt');

@q = qw(intramuralism maimedly sculpt);

ok( $s = Search::Tools::Snipper->new(
        query     => [@q],
        max_chars => length($text) - 1,
    ),
    "new snipper"
);

ok( $snip = $s->snip($text), "new snip" );

#diag($snip);
diag( $s->type_used );

ok( length($snip) < $s->max_chars, "more snip" );

# test context
my $text2 = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
EOF

my $excerpt
    = qq{type man! type! until you've reached enough words to justify your paltry existence. amen. when in the course of human events you need to create a test};

my $regex = Search::Tools->regexp( query => 'amen' );
my $snip_excerpt = Search::Tools::Snipper->new(
    query   => $regex,
    occur   => 1,
    context => 26,
);
my $snip_title = Search::Tools::Snipper->new(
    query   => $regex,
    occur   => 1,
    context => 8,
);

like( $snip_excerpt->snip($text2), qr/$excerpt/, "excerpt context" );
ok( $snip_excerpt->type('re'), "set re type" );
like( $snip_excerpt->snip($text2), qr/$excerpt/,
    "re matches loop algorithm" );
diag( $snip_excerpt->type_used );

is( $snip_title->snip($text2),
    qq{ ... justify your paltry existence. amen. when in the course ... },
    "8 context"
);
diag( $snip_title->type_used );
