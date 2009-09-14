use Test::More tests => 13;
use strict;
use warnings;
use Data::Dump qw( dump );

use_ok('Search::Tools::QueryParser');

ok( my $qparser = Search::Tools::QueryParser->new(), "new qparser" );
ok( my $query = $qparser->parse('quick brown "foxy fox"'), "parse() query" );
ok( my $terms = $query->terms, "get terms" );
is( scalar @$terms, 3, "3 terms" );
ok( my $regex = $query->regex_for( $terms->[0] ), "regex_for" );
ok( $regex->isa('Search::Tools::RegEx'), "regex isa RegEx" );
like( $terms->[0], $regex->plain, "regex matches plain" );
like( $terms->[0], $regex->html,  "regex matches html" );
isnt( $query->str, $query->str_clean, "query->str isnt query->str_clean" );
ok( my $tree = $query->tree, "get tree" );
ok( $query, "test bool overload");
is( $query, $query->str, "test string overload");
