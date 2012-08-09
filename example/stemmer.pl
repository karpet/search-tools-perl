#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools;
use Search::Tools::Snipper;
use Search::Tools::XML;
use Benchmark qw(:all);
use Lingua::Stem::Snowball;

my $stemmer       = Lingua::Stem::Snowball->new( lang => 'en' );
my $html          = Search::Tools->slurp('t/docs/big-C-Child-abuse.html');
my $buf           = Search::Tools::XML->strip_markup($html);
my $query         = Search::Tools->parser->parse('child abuse');
my $stemmed_query = Search::Tools->parser(
    stemmer => sub {
        return $stemmer->stem( $_[1] );
    }
)->parse('child abuse');

my $snipper = Search::Tools::Snipper->new(
    query     => $query,
    occur     => 1,
    context   => 25,
    max_chars => 190,
);

my $stemming_snipper = Search::Tools::Snipper->new(
    query     => $stemmed_query,
    occur     => 1,
    context   => 25,
    max_chars => 190,
);

cmpthese(
    100,
    {   'no-stem' => sub {
            my $snip = $snipper->snip($buf);
        },

        'yes-stem' => sub {
            my $snip = $stemming_snipper->snip($buf);
        },
    }
);
