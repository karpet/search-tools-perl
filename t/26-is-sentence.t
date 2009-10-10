use strict;
use Test::More tests => 10;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

# simple case
ok( my $tokenizer = Search::Tools::Tokenizer->new(), "new tokenizer" );
ok( my $tokens = $tokenizer->tokenize('I am a sentence.'), "tokenize" );
ok( $tokens->get_token(0)->is_sentence_start, "first token starts sentence" );
ok( $tokens->get_token( $tokens->num - 1 )->is_sentence_end,
    "last token ends sentence" );

# harder
ok( $tokens = $tokenizer->tokenize('lo! how a rose ere bloometh'),
    "tokenize rose" );
ok( !$tokens->get_token(0)->is_sentence_start,
    "first token not starts sentence"
);
ok( $tokens->get_token(1)->is_sentence_end, "second token is sentence end" );

# utf8 w/ punc start
ok( $tokens = $tokenizer->tokenize( to_utf8("¿Cómo estás?") ),
    "tokenize spanish" );
ok( $tokens->get_token(0)->is_sentence_start,
    "spanish " . $tokens->get_token(0) . " starts sentence" );
ok( $tokens->get_token( $tokens->len - 1 )->is_sentence_end,
    "last ? ends sentence" );
