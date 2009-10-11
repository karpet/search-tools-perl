use strict;
use Test::More tests => 10;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Data::Dump qw( dump );

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

# simple case
ok( my $tokenizer = Search::Tools::Tokenizer->new(), "new tokenizer" );
ok( my $tokens = $tokenizer->tokenize( 'I am a sentence.', qr/\w/ ),
    "tokenize" );
ok( $tokens->get_token(0)->is_sentence_start, "first token starts sentence" );
ok( $tokens->get_token( $tokens->num - 1 )->is_sentence_end,
    "last token ends sentence" );

#dump( $tokens->get_sentence_starts );

# harder
ok( $tokens = $tokenizer->tokenize( 'lo! how a rose ere bloometh', qr/\w/ ),
    "tokenize rose" );
ok( !$tokens->get_token(0)->is_sentence_start,
    "first token not starts sentence"
);
ok( $tokens->get_token(1)->is_sentence_end, "second token is sentence end" );

#dump( $tokens->get_sentence_starts );

# utf8 w/ punc start
ok( $tokens = $tokenizer->tokenize( to_utf8("¿Cómo estás?"), qr/\w/ ),
    "tokenize spanish" );
ok( $tokens->get_token(0)->is_sentence_start,
    "spanish " . $tokens->get_token(0) . " starts sentence" );
ok( $tokens->get_token( $tokens->len - 1 )->is_sentence_end,
    "last ? ends sentence" );

#dump( $tokens->get_sentence_starts );
