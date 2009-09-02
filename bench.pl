#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Benchmark qw(:all);
use File::Slurp;

my $greek     = to_utf8( read_file('t/docs/greek_and_ojibwe.txt') );
my $ascii     = to_utf8( read_file('t/docs/ascii.txt') );
my $regex     = qr/\w+(?:'\w+)*/;
my $tokenizer = Search::Tools::Tokenizer->new( re => $regex );

cmpthese(
    10000,
    {   'pure-perl-greek' => sub {
            my $tokens = $tokenizer->tokenize_pp( $greek, \&heat_seeker );
        },
        'pure-perl-bare-greek' => sub {
            my $tokens
                = $tokenizer->tokenize_pp_bare( $greek, \&heat_seeker );
        },
        'xs-greek' => sub {
            my $tokens = $tokenizer->tokenize( $greek, \&heat_seeker );
        },
        'pure-perl-ascii' => sub {
            my $tokens = $tokenizer->tokenize_pp( $ascii, \&heat_seeker );
        },
        'pure-perl-bare-ascii' => sub {
            my $tokens
                = $tokenizer->tokenize_pp_bare( $ascii, \&heat_seeker );
        },
        'xs-ascii' => sub {
            my $tokens = $tokenizer->tokenize( $ascii, \&heat_seeker );
        },
    }
);

sub heat_seeker {

    # trivial case no-op just to measure sub call overhead
}

