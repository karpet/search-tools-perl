use strict;
use warnings;
use Data::Dump qw( dump );
use Test::More tests => 10;
use File::Slurp;

use_ok('Search::Tools');
use_ok('Search::Tools::Tokenizer');
use Search::Tools::UTF8;

my $str = <<EOF;
these are some words we expect (don't we?) the
tokenizer to handle with aplomb.
If it can't, well, then... back to the drawing board!
EOF

my $greek = read_file('t/greek_and_ojibwe.txt');
$greek = to_utf8($greek);

ok( my $tokenizer = Search::Tools::Tokenizer->new( re => qr/\w+(?:'\w+)*/ ),
    "new tokenizer" );

ok( my $tokens = $tokenizer->tokenize( $str, \&handler ),
    "tokenize str for tokens" );

my $count = 0;
while ( my $tok = $tokens->next ) {
    ok( $tok->str, "tok->str" );
    cmp_ok( $tok->len, '>=', 1, "tok->len >= 1" );
    ok( $tok->chrs,           "tok->chrs" );
    ok( defined $tok->offset, "tok->offset defined" );
    $count++;
}
is($count, 24, "count");

ok( my $grtokens = $tokenizer->tokenize( $greek, \&handler ),
    "tokenize greek" );

sub handler {
    warn dump( \@_ );
}
