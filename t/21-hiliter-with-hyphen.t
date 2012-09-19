#!/usr/bin/env perl
use strict;

use Search::Tools::UTF8;
use Search::Tools::HiLiter;
use Test::More tests => 9;

my $parser
    = Search::Tools->parser( word_characters => q/\w/ . quotemeta(q/'./) );

my $hiliter
    = Search::Tools::HiLiter->new( query => $parser->parse(q( Kennedy )) );

#Data::Dump::dump($hiliter);

my $str_no_hyphen   = to_utf8(q/Martha Kennedy Smith/);
my $str_with_hyphen = to_utf8(q/Martha Kennedy-Smith/);

like( $hiliter->light($str_no_hyphen),
    qr/<span/, 'hiliter works fine without hyphens' );
like( $hiliter->light($str_with_hyphen),
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

diag( "\$re: " . $re );

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

my $plain_re = $hiliter->query->regex_for('kennedy')->plain;
my $html_re  = $hiliter->query->regex_for('kennedy')->html;

Search::Tools::describe($plain_re);
Search::Tools::describe($html_re);
Search::Tools::describe($re);
Search::Tools::describe($str_with_hyphen);

like( $str_no_hyphen,   $kennedy_re, "dumb match no hyphen" );
like( $str_no_hyphen,   $re,         "hardcoded regex dumb match no hyphen" );
like( $str_with_hyphen, $kennedy_re, "dumb match with hyphen" );
like( $str_with_hyphen, $re,         "hardcoded dumb match with hyphen" );
like( $str_with_hyphen, $html_re,    "html match with hyphen" );
like( $str_with_hyphen, $plain_re,   "plain match with hyphen" );
like( $str_no_hyphen,   $html_re,    "html match with no hyphen" );
like( $str_no_hyphen,   $plain_re,   "plain match with no hyphen" );

# perl >= 5.14 changes how qr// serializes
# so just ignore this test. it's arrived at via above tests anyway.
#is( $re, $plain_re, "plain regex match" );
#is( $kennedy_re, $re, "simple re cmp");
#is( $old_re, $re, "before vs after" );

#diag( '-' x 80 );
#diag($kennedy_re);
