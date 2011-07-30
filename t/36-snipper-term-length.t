#!/usr/bin/env perl
use strict;
use Test::More tests => 7;

use_ok('Search::Tools::Snipper');
use_ok('Search::Tools::HiLiter');

my $text = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
EOF

my @q = ( 'a', 'in', '"human events"' );

ok( my $s = Search::Tools::Snipper->new(
        query           => join( ' ', @q ),
        max_chars       => length($text) - 1,
        term_min_length => 2,
    ),
    "snipper"
);

ok( my $snip = $s->snip($text), "snip" );
ok( my $h = Search::Tools::HiLiter->new( query => $s->query ), "hiliter" );
ok( my $lit = $h->light($snip), "hilite" );

#diag($snip);
#diag($lit);

is( $snip,
    qq/ ... in the course of human events you need to create ... /,
    "snip excludes terms less than 2 chars long"
);
