use Search::Tools::HiLiter;
use Test::More tests => 9;

my $parser
    = Search::Tools->parser( word_characters => q/\w/ . quotemeta(q/'./) );

#Data::Dump::dump( $regexp );

my $hiliter
    = Search::Tools::HiLiter->new( query => $parser->parse(q( Kennedy )) );

#Data::Dump::dump($hiliter);

like( $hiliter->light(q/Martha Kennedy Smith/),
    qr/<span/, 'hiliter works fine without hyphens' );
like( $hiliter->light(q/Martha Kennedy-Smith/),
    qr/<span/, 'hiliter ought to work with hyphens' );

my $kennedy_re = qr/
(
\A|(?i-xsm:[\Q'-\E]*)(?si-xm:(?:[\s\x20]|[^\w\Q'\E\.])+)(?i-xsm:[\Q'-\E]?)
)
(
kennedy
)
(
\Z|(?i-xsm:[\Q'-\E]*)(?si-xm:(?:[\s\x20]|[^\w\Q'\E\.])+)(?i-xsm:[\Q'-\E]?)
)
/xis;

my $re = qr/
(
\A|(?i-xsm:[\'\-]*)(?si-xm:(?:[\s\x20]|[^\w\'\.])+)(?i-xsm:[\'\-]?)
)
(
kennedy
)
(
\Z|(?i-xsm:[\'\-]*)(?si-xm:(?:[\s\x20]|[^\w\'\.])+)(?i-xsm:[\'\-]?)
)
/xis;

my $old_re = qr/
(
\A|(?i-xsm:[\'\-]*)(?si-xm:(?:[\s\x20]|[^\w\'\.])+)(?i-xsm:[\'\-]?)
)
(
kennedy
)
(
\Z|(?i-xsm:[\'\-]*)(?si-xm:(?:[\s\x20]|[^\w\'\.])+)(?i-xsm:[\'\-]?)
)
/xis;

like( q/Martha Kennedy Smith/, $kennedy_re, "dumb match no hyphen" );
like( q/Martha Kennedy-Smith/, $kennedy_re, "dumb match with hyphen" );
like(
    q/Martha Kennedy-Smith/,
    $hiliter->query->regex_for('kennedy')->html,
    "html match with hyphen"
);
like(
    q/Martha Kennedy-Smith/,
    $hiliter->query->regex_for('kennedy')->plain,
    "plain match with hyphen"
);
like(
    q/Martha Kennedy Smith/,
    $hiliter->query->regex_for('kennedy')->html,
    "html match with no hyphen"
);
like(
    q/Martha Kennedy Smith/,
    $hiliter->query->regex_for('kennedy')->plain,
    "plain match with no hyphen"
);

# perl >= 5.14 changes how qr// serializes
# so just ignore this test. it's arrived at via above tests anyway.
#is( $kennedy_re,
#    $hiliter->query->regex_for('kennedy')->plain,
#    "plain regex match"
#);

#is( $kennedy_re, $re, "simple re cmp");
is( $old_re, $re, "before vs after" );

#diag( '-' x 80 );
#diag($kennedy_re);
