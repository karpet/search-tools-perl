use Search::Tools::HiLiter;
use Test::More tests => 2;

{

    # the OO way
    my $regexp = Search::Tools::RegExp->new(
        word_characters => '\w' . quotemeta("'.") );

    my $hiliter = Search::Tools::HiLiter->new(
        query => $regexp->build( [qw( Kennedy )] ) );

    like( $hiliter->light(q{Martha Kennedy Smith}),
        qr/<span/, 'hiliter works fine without hyphens' );
    like( $hiliter->light(q{Martha Kennedy-Smith}),
        qr/<span/, 'hiliter ought to work with hyphens' );
}
