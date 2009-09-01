#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools::Tokenizer;
use Search::Tools::UTF8;
use Benchmark qw(:all);
use File::Slurp;

my $greek = to_utf8( read_file('t/docs/greek_and_ojibwe.txt') );
my $ascii = to_utf8( read_file('t/docs/ascii.txt') );
my $regex = qr/\w+(?:'\w+)*/;

cmpthese(
    100000,
    {   'pure-perl-greek' => sub { pure_perl($greek) },
        'xs-greek'        => sub {
            my $tokenizer = Search::Tools::Tokenizer->new( re => $regex );
            my $tokens = $tokenizer->tokenize($greek);
        },
        'pure-perl-ascii' => sub { pure_perl($ascii) },
        'xs-ascii'        => sub {
            my $tokenizer = Search::Tools::Tokenizer->new( re => $regex );
            my $tokens = $tokenizer->tokenize($ascii);
        },
    }
);

sub heat_seeker {
    return 0;    # trivial case
}

sub pure_perl {
    my @tokens = ();
    my $i      = 0;
    for ( split( m/($regex)/, $_[0] ) ) {
        push(
            @tokens,
            {   'pos'    => $i++,
                str      => $_,
                is_hot   => heat_seeker($_),
                is_match => ( $_ =~ m/^$regex$/ ) ? 1 : 0,
            }
        );
    }

}
