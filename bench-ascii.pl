#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Benchmark qw(:all);
use File::Slurp;

my $ascii      = read_file('t/docs/test.txt');
my $ascii_utf8 = to_utf8($ascii);
my $regex      = qr/\w+(?:'\w+)*/;

cmpthese(
    10000,
    {   'ascii-pp'      => sub { pure_perl($ascii) },
        'ascii_utf8-pp' => sub { pure_perl($ascii_utf8) },
        'ascii-xs'      => sub {
            my $tokenizer = Search::Tools::Tokenizer->new( re => $regex );
            my $tokens = $tokenizer->tokenize($ascii);
        },
        'ascii_utf8-xs' => sub {
            my $tokenizer = Search::Tools::Tokenizer->new( re => $regex );
            my $tokens = $tokenizer->tokenize($ascii_utf8);
        },
    }
);

sub heat_seeker {
    return 0;    # trivial case
}

sub pure_perl {
    my @tokens = split( m/($regex)/, to_utf8( $_[0] ) );
    my %markers;
    my $i = 0;
    for (@tokens) {
        $markers{$i} = {
            'pos'    => $i,
            str      => $_,
            is_hot   => heat_seeker($_),
            is_match => ( $_ =~ m/^$regex$/ ) ? 1 : 0,
        };
        $i++;
    }
}
