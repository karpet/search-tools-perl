#!/usr/bin/perl

use strict;
use warnings;

use Search::Tools;
use Data::Dump qw/pp/;


for my $q (@ARGV)
{
    my $re = Search::Tools->regexp( query => $q );

    for my $w ($re->keywords)
    {
        print "$q -> $w\n";
    }
}