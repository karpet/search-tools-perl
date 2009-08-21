use Test::More tests => 18;
BEGIN { use_ok('Search::Tools::Keywords') }

my %q = (
    'the quick'                         => 'quick',         # stopwords
    'color:brown       fox'             => 'brown fox',     # fields
    '+jumped and +ran         -quickly' => 'jumped ran',    # booleans
    '"over the or lazy        and dog"' =>
        'over the or lazy and dog',                         # phrase
    'foo* food bar' => 'foo* food bar',                     # wildcard
    'foo foo*'      => 'foo*',                              # unique wildcard
    'field:(foo not bar and (baz or goo))' => 'foo baz goo',    #compound
    'foo?bar\@biz'                         => 'foo bar biz',    # nonwordchars
    "O'reilly, don't ask me why, please don't!" =>
        "O'reilly ask me why please don't"
    ,    # contractions (NOTE duplicate don't is removed)
    "'-edgy' aren't we?-" => "edgy aren't we",    # edge case
    "site:foo.com bar"    => "bar",               # ignore fields
);

ok( my $kw = Search::Tools::Keywords->new(
        stopwords     => 'the',
        ignore_case   => 0,
        ignore_fields => [qw( site )],
    ),
    "kw object created"
);

for my $query ( keys %q ) {
    is( join( ' ', $kw->extract($query) ), $q{$query}, "$query" );
}

%q = (
    'c++ compiler'    => 'c compiler',
    '"--foo option"'  => 'foo option',
    '"option --less"' => 'option less',
);

ok( $kw->ignore_first_char('-') );
ok( $kw->ignore_last_char('+') );

for my $query ( keys %q ) {
    is( join( ' ', $kw->extract($query) ), $q{$query}, $query );
}
