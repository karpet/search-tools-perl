#!/usr/bin/perl
#
# Copyright (c) 2006 Peter Karman - perl@peknet.com
#
# mostly from the SWISH::API man page
# plus Search::Tools stuff
#

require 5.008;
use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use FindBin;
use lib "$FindBin::Bin/../lib";

use POSIX qw(locale_h);
use locale;

use SWISH::API;
use Search::Tools;
use Getopt::Long;
use Encode;
use Text::Wrap;
use File::Basename;

my %skip       = ();                # properties to skip in output
my $debug      = 0;
my $high       = undef;
my $low        = undef;
my $property   = undef;
my $i          = 'index.swish-e';
my $maxresults = undef;
my $help       = 0;
my $col        = 20;                # width of gutter between props and text
my $script     = basename($0);
my ($charset) = (setlocale(LC_CTYPE) =~ m/^.+?\.(.+)/ || 'iso-8859-1');

my $usage = <<HELP;

    $script [opts] query
    
    $script is a Perl-based debugger for Swish-e indexes.
    
    $script will dump all properties for matches to 'query'.
    
    In addition, long properties will be snipped
    and highlighted using the Search::Tools modules.

    $script is NOT a replacement for the swish-e tool. It
    is an example of using SWISH::API and Search::Tools
    together.
    
    Options:
    
     --index name       specify index name ($i)
     --debug [n]        turn on debugging
     --property propname
                        limit results by 'propname'
     --high val         with --property, set high limit
     --low  val         with --property, set low limit
     --max  n           maximum number of results to print
     --charset charset  convert properties to UTF8 from 'charset' ($charset)
     --help             print this message
     
HELP

GetOptions(
           'debug:i'    => \$debug,
           'index=s'    => \$i,
           'high=s'     => \$high,
           'low=s'      => \$low,
           'property=s' => \$property,
           'max=i'      => \$maxresults,
           'help'       => \$help,
           'charset'    => \$charset,
          )
  or die $usage;

die $usage if $help;
die $usage unless @ARGV;

my $q = join(' ', @ARGV);

my $swish = SWISH::API->new($i);

$swish->AbortLastError
  if $swish->Error;

# ignoreWordCount not always on
#$swish->RankScheme( 1 );

# Or more typically
my $search = $swish->New_Search_Object;

if ($property)
{
    $search->SetSearchLimit($property, $low, $high);
    $swish->AbortLastError if $swish->Error;
}

# then in a loop
my $results = $search->Execute($q);

# always check for errors (but aborting is not always necessary)

$swish->AbortLastError
  if $swish->Error;

# Display a list of results

my $hits = $results->Hits;
$maxresults ||= $hits;
if (!$hits)
{
    print "No Results\n";
    exit;
}

print "Found $hits hits\n";

my $kwre = Search::Tools->regexp(
    debug            => $debug,
    query            => join(' ', $results->ParsedWords($i)),
    stemmer          => \&stem,
    word_characters  => to_utf8(($swish->HeaderValue($i, 'WordCharacters'))[0]),
    end_characters   => to_utf8(($swish->HeaderValue($i, 'EndCharacters'))[0]),
    begin_characters =>
      to_utf8(($swish->HeaderValue($i, 'BeginCharacters'))[0]),
    ignore_first_char =>
      to_utf8(($swish->HeaderValue($i, 'IgnoreFirstChar'))[0]),
    ignore_last_char => to_utf8(($swish->HeaderValue($i, 'IgnoreLastChar'))[0]),
    charset          => $charset,

                                );
my $snipper = Search::Tools->snipper(debug => $debug, query => $kwre);

my $hiliter = Search::Tools->hiliter(debug => $debug, query => $kwre, tty => 1);

my $fw = $swish->fuzzify($i, $q);

my @fuzz = $fw->WordList;

print "fuzzy: ", join(' ', @fuzz), "\n";

my $stemmed = stem(undef, $q);

print "stemmed query: $stemmed\n";

my $count  = 0;
my $larrow = Encode::encode_utf8(chr(187));
my $rarrow = Encode::encode_utf8(chr(171));

while (my $result = $results->NextResult)
{
    last if ++$count > $maxresults;

    print "~" x 80 . "\n";

    my @props = $result->PropertyList;

  PROP: for my $prop (sort { $a->Name cmp $b->Name } @props)
    {

        my $n = $prop->Name;

        next PROP if exists $skip{$n};

        my $v = $result->Property($n) || '';
        $v = to_utf8($v);

        if ($n eq 'swishlastmodified')
        {
            $v = localtime($v);
        }
        else
        {
            $v = $snipper->snip($v) if length($v) > 80;
            $v = $hiliter->light($v);
        }

        # Text::Wrap has a undesirable effect of indenting on right side
        # the same amount as left, so we hack around that for prettier printing

        my $space   = ' ' x ($col - length($n));
        my $gutter  = ' ' x $col;
        my $wrapped = wrap("", "", $v);
        $wrapped =~ s,\n,\n$gutter,g;
        print($n, $space, $larrow, $wrapped, $rarrow, "\n");

    }

}

# this function also passed as stemmer param to S::T::KeyWords
sub stem
{
    if ($SWISH::API::VERSION < 0.04)
    {
        die "stem() requires SWISH::API version 0.04 or newer\n";
    }

    my $kwobj = shift;
    my $w     = shift;

    my $fw = $swish->Fuzzify($i, $w);

    my @fuzz = $fw->WordList;

    if (my $e = $fw->WordError)
    {

        warn "Error in Fuzzy WordList ($e): $!\n";
        return undef;

    }

    return $fuzz[0];    # we ignore possible doublemetaphone

}

sub to_utf8
{
    return Encode::encode_utf8(Encode::decode($charset, $_[0], 1));
}
