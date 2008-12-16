#!/usr/bin/perl
use strict;
use Test::More tests => 1;
use Search::Tools::Transliterate;
use utf8;

binmode STDERR, ':utf8';

my $string = "ăşţâîĂŞŢÂÎ";
my $ascii = 'astaiASTAIsStT';

# new romanian utf8 chars
$string .= "\x{0218}";
$string .= "\x{0219}";
$string .= "\x{021A}";
$string .= "\x{021B}";

my $tr = Search::Tools::Transliterate->new(ebit=>0);
$tr->map->{"\x{0218}"} = 's';
$tr->map->{"\x{0219}"} = 'S';
$tr->map->{"\x{021A}"} = 't';
$tr->map->{"\x{021B}"} = 'T';

#print STDERR $string . "\n";
#print STDERR $tr->convert($string) . "\n";

is($ascii, $tr->convert($string), "transliterate with map");

1;

