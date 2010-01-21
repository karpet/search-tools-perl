#!/usr/bin/perl
use strict;
use Test::More tests => 6;
use Data::Dump qw( dump );
use Search::Tools::Transliterate;
use Search::Tools::UTF8;
use utf8;

binmode STDERR, ':utf8';

my $string = "ăşţâîĂŞŢÂÎ";
my $ascii  = 'astaiASTAIsStT';

# new romanian utf8 chars
$string .= "\x{0218}";
$string .= "\x{0219}";
$string .= "\x{021A}";
$string .= "\x{021B}";

my $tr = Search::Tools::Transliterate->new( ebit => 0 );
$tr->map->{"\x{0218}"} = 's';
$tr->map->{"\x{0219}"} = 'S';
$tr->map->{"\x{021A}"} = 't';
$tr->map->{"\x{021B}"} = 'T';

#print STDERR $string . "\n";
#print STDERR $tr->convert($string) . "\n";

is( $ascii, $tr->convert($string), "transliterate with map" );

# test 0.21 and 0.22 bugs
my $tr2 = Search::Tools::Transliterate->new( ebit => 0 );

ok( keys %{ $tr2->map }, "map init has keys" );

my $tr3 = Search::Tools::Transliterate->new( ebit => 1 );

is( $tr3->map->{"\x{0218}"}, 'Ş', "ebit 1 3rd instance" );

# win1252

#$tr->debug(1);
my $win1252 = "\x80\x82\x83\x91\x92\x93\x94\x9f";
ok( looks_like_win1252($win1252), "looks_like_win1252" );
ok( my $win1252_conv = $tr->convert1252($win1252), "convert1252" );

#diag( dump $win1252_conv );
is( $win1252_conv, qq{EUR'f''""Y}, "transliterate 1252" );

1;

