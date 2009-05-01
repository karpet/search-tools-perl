use Search::Tools::HiLiter;
use Test::More tests => 4;

{

    # package var to control word definition
    local $Search::Tools::RegExp::WordChar
        = $Search::Tools::RegExp::UTF8Char . quotemeta("'.");    # no hyphen

    my $hiliter = Search::Tools::HiLiter->new( query => [qw( Kennedy )] );

    like( $hiliter->light(q{Martha Kennedy Smith}),
        qr/<span/, 'hiliter works fine without hyphens' );
    like( $hiliter->light(q{Martha Kennedy-Smith}),
        qr/<span/, 'hiliter ought to work with hyphens' );
}

diag($Search::Tools::RegExp::WordChar);

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
