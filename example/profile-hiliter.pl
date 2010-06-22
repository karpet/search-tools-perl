#!/usr/bin/perl
use strict;
use warnings;
use Search::Tools;
use Search::Tools::HiLiter;
use Search::Tools::XML;
use File::Slurp;
use Path::Class;

my $buf     = read_file('t/docs/ascii.txt');
my $query   = Search::Tools->parser->parse('thronger');
my $hiliter = Search::Tools::HiLiter->new( query => $query, );
my $count   = 0;
while ( $count++ < 10000 ) {

    my $lit = $hiliter->light($buf);

}
