#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw( dump );
use Test::More tests => 4;
use Search::Tools;

use_ok('Search::Tools::Query');

my $text = 'one two three four';
my $html = 'one <b>t</b>wo three <strong>four</strong>';

ok( my $query = Search::Tools->parser->parse('two'), "new query" );
is( $query->matches_text($text), 1, "one text match" );
is( $query->matches_html($html), 1, "one html match" );
