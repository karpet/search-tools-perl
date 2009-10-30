#!perl -w
use strict;
use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 2 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;

use Search::Tools::Snipper;

leaks_cmp_ok {
    my $snipper
        = Search::Tools::Snipper->new( query => 'three', max_chars => 1 );
}
'<', 1;

leaks_cmp_ok {
    my $snipper
        = Search::Tools::Snipper->new( query => 'three', max_chars => 1 );
    my $snip = $snipper->snip('one two three four five');
}
'<', 1;
