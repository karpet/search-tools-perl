#!/usr/bin/env perl
use strict;
use Test::More tests => 8;
use lib 't';
use Data::Dump qw( dump );
use_ok('Search::Tools::Snipper');
use_ok('Search::Tools::HiLiter');

my $file = 't/docs/snip-phrases.txt';
my $q    = qq/"united states"/;
my $buf  = Search::Tools->slurp($file);

my $snipper = Search::Tools::Snipper->new(
    query         => $q,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
                             #debug         => 1,
    treat_phrases_as_singles => 0,    # keep phrases together
);

#dump $snipper;
ok( my $snip = $snipper->snip($buf), "snip buf" );
ok( length $snip, "snip has length" );

# proximity syntax
$q       = qq/"live united"~5/;
$snipper = Search::Tools::Snipper->new(
    query         => $q,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
                             #debug         => 1,
    treat_phrases_as_singles =>
        0,    # keep phrases together, but snipper should detect proximity
);

#dump $snipper;

ok( $snip = $snipper->snip($buf), "snip buf" );
ok( length $snip, "snip has length" );

#diag($snip);

# snip a phrase with a dot
diag("snip phrase with a dot");
$q = qq/"st. john's"/;
my $snipper2 = Search::Tools::Snipper->new(

    #debug         => 1,
    query         => $q,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
    treat_phrases_as_singles =>
        0,    # keep phrases together, but snipper should detect proximity
);

#dump $snipper;

ok( $snip = $snipper2->snip($buf), "snip buf" );
ok( length $snip, "snip has length" );

diag($snip);

