use Test::More tests => 13;
use strict;
use warnings;
use Data::Dump qw( dump );

use_ok('Search::Tools::QueryParser');

ok( my $qparser = Search::Tools::QueryParser->new(), "new qparser" );
ok( my $query = $qparser->parse('quick brown "foxy fox"'), "parse() query" );
ok( my $keywords = $query->keywords, "get keywords" );
is( scalar @$keywords, 3, "3 keywords" );
ok( my $regex = $query->regex_for( $keywords->[0] ), "regex_for" );
ok( $regex->isa('Search::Tools::RegExp::Keyword'), "regex isa Keyword" );
like( $keywords->[0], $regex->plain, "regex matches plain" );
like( $keywords->[0], $regex->html,  "regex matches html" );
isnt( $query->str, $query->str_clean, "query->str isnt query->str_clean" );
ok( my $tree = $query->tree, "get tree" );
ok( $query, "test bool overload");
is( $query, $query->str, "test string overload");
