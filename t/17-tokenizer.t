use strict;
use warnings;
use Data::Dump qw( dump );
use Test::More tests => 924;
use File::Slurp;

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

use_ok('Search::Tools');
use_ok('Search::Tools::Tokenizer');
use Search::Tools::UTF8;

my $simple = "foo bar baz";

my $str = <<EOF;
these are some words we expect (don't we?) the
tokenizer to handle with aplomb.
If it can't, well, then... back to the drawing board!
EOF

my $str2 = <<EOF;
!@#$%^    some strings with non-token at the start and end !@#$%^&*() 
EOF

my $greek = read_file('t/greek_and_ojibwe.txt');
$greek = to_utf8($greek);

ok( my $tokenizer = Search::Tools::Tokenizer->new(), "new tokenizer" );

ok( my $simple_tokens = $tokenizer->tokenize($simple), "tokenize simple" );
is( check_tokens($simple_tokens), 5, "5 simple tokens" );

ok( my $tokens = $tokenizer->tokenize($str), "tokenize str for tokens" );
is( check_tokens($tokens), 48, "str count" );

ok( my $tokens2 = $tokenizer->tokenize($str2), "tokenize str2" );
is( check_tokens($tokens2), 25, "str2 count" );
ok( my $grtokens = $tokenizer->tokenize($greek), "tokenize greek" );
is( check_tokens($grtokens), 99, "grtokens count" );

# snip

sub handler {
    warn dump( \@_ );
}

sub check_tokens {
    my $tokens = shift;
    my $count  = 0;
    while ( my $tok = $tokens->next ) {
        ok( length( $tok->str ), "tok->str" );

        #diag( $tok->str );
        cmp_ok( $tok->len, '>=', 1, "tok->len >= 1" );
        ok( defined $tok->pos,          "token pos" );
        ok( defined $tok->set_match(0), "set match" );
        ok( defined $tok->set_hot(1),   "set hot" );

        $count++;
    }
    is( $count,       $tokens->num, "count == num" );
    is( $tokens->pos, $tokens->num, "pos == num-1 when all seen" );
    is( $tokens->len, $tokens->num, "len == num" );
    is( scalar( @{ $tokens->as_array } ), $count, "get as_array" );
    ok( defined $tokens->get_token(0), "get first token" );
    ok( my $matches = $tokens->matches, "get matches" );

    # only place this would not be true
    # is an original string of one token
    cmp_ok( scalar(@$matches), '<', $count, "matches < count" );

    #dump($tokens);
    return $count;

}
