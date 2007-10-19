use Test::More tests => 2;

BEGIN
{
    use POSIX qw(locale_h);
    use locale;
    setlocale(LC_CTYPE, 'en_US.UTF-8');
}


use Search::Tools;

{
    package foo;
    sub summary { $_[0]->{summary} }
}

my @search_results = (bless({summary => 'my brown fox is quick'}, 'foo'));

my $query = 'the quik brown fox';

my $re = Search::Tools->regexp(query => $query);

my $snipper    = Search::Tools->snipper(query    => $re);
my $hiliter    = Search::Tools->hiliter(query    => $re);
my $spellcheck = Search::Tools->spellcheck(query => $re);

my $suggestions = $spellcheck->suggest($query);

my $ok;
for my $v (@$suggestions)
{
   $ok += scalar @{$v->{suggestions}};
}

SKIP: {

    skip "No valid suggestions found. Missing dictionary?", 2 unless $ok;

for my $s (@$suggestions)
{
    if (!$s->{suggestions})
    {

        # $s->{word} was spelled correctly
    }
    elsif (@{$s->{suggestions}})
    {
        ok("Did you mean: " . join(' or ', @{$s->{suggestions}}) . "\n");
    }
}

for my $result (@search_results)
{
    ok($hiliter->light($snipper->snip($result->summary)));
}


}
