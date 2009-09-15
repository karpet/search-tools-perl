use Test::More tests => 6;

use_ok('Search::Tools::RegExp');

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

my %q = (
    'the apples' => 'apple',    # stopwords

);

ok( my $qparser = Search::Tools->parser(
        lang      => 'en_us',
        stopwords => 'the brown',
        stemmer   => sub {
            my $w = $_[1];
            $w =~ s/s$//;
            return $w;

        }
    ),

    "new qparser"
);

ok( my $query = $qparser->parse( join( ' ', keys %q ) ), "parse query" );

#Data::Dump::dump $kw;

is( $query->num_terms, 1, "1 term" );

for my $term ( @{ $query->terms } ) {
    my $r     = $query->regex_for($term);
    my $plain = $r->plain;
    my $html  = $r->html;

    like( $term, qr{^$plain$}, $term );
    like( $term, qr{^$html$},  $term );

    #diag($plain);

}
