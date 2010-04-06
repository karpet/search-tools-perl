#!/usr/bin/env perl
use strict;
use Test::More tests => 15;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Search::Tools::Snipper;
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

ok( my $snipper = Search::Tools::Snipper->new(
        query        => 'foo',
        as_sentences => 1,
        max_chars    => 5,
    ),
    "new snipper"
);

ok( my $snip = $snipper->snip('Text with match near the foo'), "snip foo" );
is( $snip, 'Text ... ', "got snip" );

my $long_text = <<EOF;
This is a long section of text with foo. First, there is an intro sentence.
Second, there is an explanation about foo. Third, and finally for foo, 
there is a conclusion that ties it all together.
EOF

my $long_text_snip
    = qq/This is a long section of text with foo. ... Second, there is an explanation about foo. ... Third, and finally for foo, there is a conclusion that ties it all together. /;

my $long_snipper = Search::Tools->snipper(
    query => 'foo',

    #debug         => 1,
    occur         => 3,      # number of snips
    context       => 100,    # number of words in each snip
    as_sentences  => 1,
    ignore_length => 1,      # ignore max_chars, return entire snippet.
    show          => 0,      # only show if match, no dumb substr
    treat_phrases_as_singles => 0,    # keep phrases together
);

ok( my $long_snip = $long_snipper->snip($long_text), "snip long text" );

#diag($long_snip);
is( $long_snip, $long_text_snip, "long text snip" );
