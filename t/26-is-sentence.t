use strict;
use Test::More tests => 5;
use Search::Tools::Tokenizer;

ok( my $tokenizer = Search::Tools::Tokenizer->new(), "new tokenizer" );
ok( my $tokens = $tokenizer->tokenize('I am a sentence.'), "tokenize" );

while ( my $tok = $tokens->next ) {
    $tok->dump;

}
