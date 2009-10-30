use strict;
use Test::More tests => 2;
use lib 't';
eval 'use IO::Uncompress::Gunzip ()';
plan skip_all => 'IO::Uncompress::Gunzip is required to test bigfile'
    if $@;

use Search::Tools::XML;
use Search::Tools::Snipper;

my $file = 't/docs/bigfile.html.gz';
my $q    = qq/child adoption/;
my $fh   = IO::Uncompress::Gunzip->new($file);
my $buf;
{
    local $/;
    $buf = <$fh>;
    $buf = "$buf $buf $buf";    # 3x for big fun
}
diag( "working on " . length($buf) . " html bytes" );
my $plain = Search::Tools::XML->strip_html($buf);
diag( "working on " . length($plain) . " plain bytes" );
my $snipper = Search::Tools::Snipper->new(
    query               => $q,
    occur               => 1,
    context             => 25,
    max_chars           => 190,
    as_sentences        => 1,
    type                => 'token',    # because we want to profile
);
my $snip = $snipper->snip($plain);

like( $snip, qr/child .+ child/, "match snip" );
cmp_ok( length $snip, '<', 200, "length is sane" );
