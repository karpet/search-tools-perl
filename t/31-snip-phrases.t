#!/usr/bin/env perl
use strict;
use Test::More tests => 3;
use lib 't';
use Data::Dump qw( dump );
use File::Slurp;
use_ok('Search::Tools::Snipper');
use_ok('Search::Tools::HiLiter');

my $file = 't/docs/snip-phrases.txt';
my $q    = qq/"united states"/;
my $buf  = read_file($file);

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

ok( length $snipper->snip($buf) );
