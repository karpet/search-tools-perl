#!/usr/bin/perl
#
# sort of like GNU grep
#

use strict;
use warnings;

no Time::TimeTick;
use File::Slurp;
use Search::Tools;

my $usage = "$0 'query' file(s) \n";

my $query = shift @ARGV or die $usage;
my @files = @ARGV       or die $usage;

timetick('start snipper');
my $snipper =
  Search::Tools->snipper(
                         query               => $query,
                         collapse_whitespace => 1,
                         re_snip             => 1,
                         occur               => 4,
                         context             => 12
                        );
timetick('  end snipper');

timetick('start hiliter w/ compiled query and tty');
my $hiliter = Search::Tools->hiliter(query => $snipper->rekw, tty => 1);
timetick('  end hiliter w/ compiled query and tty');

for my $f (@files)
{

    # print "FILE: $f\n";

    timetick('start file');
    my $text = read_file($f);
    timetick('  end file');

    timetick('start snip');
    my $snip = $snipper->snip($text);
    timetick('  end snip');

    if (!$snip)
    {

        #warn "no snip for $f\n";
        next;
    }

    timetick('start light');
    print "$f: " . $hiliter->light($snip), $/;
    timetick('  end light');

}
