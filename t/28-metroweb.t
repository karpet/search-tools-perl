use strict;
use warnings;
use Test::More tests => 4;    # TODO real tests
use File::Slurp;

use_ok('Search::Tools');
use_ok('Search::Tools::Snipper');
use_ok('Search::Tools::XML');
use_ok('Search::Tools::UTF8');

my $buf = Search::Tools::XML->strip_html(
    to_utf8( scalar read_file('t/docs/metroweb.html') ) );
my $parser = Search::Tools->parser( ignore_fields => [qw( site )] );
my $q1 = $parser->parse(
    qq(site:www.metroweb.co.za entirely voluntary and at your own risk));
my $q2 = $parser->parse(qq(site:www.metroweb.co.za usenet));
my $q3 = $parser->parse(qq(site:www.metroweb.co.za bulletin boards));
my $q4 = $parser->parse(qq(site:www.metroweb.co.za chat rooms));

my $snipper1 = Search::Tools::Snipper->new(
    context      => 25,
    as_sentences => 1,
    query        => $q1
);
my $snip1    = $snipper1->snip($buf);
my $snipper2 = Search::Tools::Snipper->new(
    context      => 25,
    as_sentences => 1,
    query        => $q2
);
my $snip2    = $snipper2->snip($buf);
my $snipper3 = Search::Tools::Snipper->new(
    context      => 25,
    as_sentences => 1,
    query        => $q3
);
my $snip3    = $snipper3->snip($buf);
my $snipper4 = Search::Tools::Snipper->new(
    context      => 25,
    as_sentences => 1,
    query        => $q4
);
my $snip4 = $snipper3->snip($buf);

diag($snip1);
diag($snip2);
diag($snip3);
diag($snip4);
