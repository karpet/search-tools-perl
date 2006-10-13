use Test::More tests => 8;

#use Data::Dump qw(pp);
use Search::Tools::Keywords;
use Search::Tools::SpellCheck;

my $query =
  'asdfasdf the quik foo=foxx color:browwn and "lazay dogg" not jumped';

my $kw = Search::Tools::Keywords->new;

ok(
    my $spellcheck =
      Search::Tools::SpellCheck->new(
                                     max_suggest => 4,
                                     kw          => $kw
                                    ),
    "spellcheck object"
  );

my $suggestions = $spellcheck->suggest($query);

#diag(pp($suggestions));

my %expect = (
              'the'      => 0,
              'quik'     => 4,
              'foxx'     => 3,
              'browwn'   => 4,
              'lazay'    => 4,
              'dogg'     => 4,
              'asdfasdf' => undef
             );

for my $s (@$suggestions)
{
    my $count = $expect{$s->{word}};

    if (!defined $count)
    {
        ok(!@{$s->{suggestions}}, $s->{word});
    }
    elsif ($count == 0)
    {
        ok($s->{suggestions} == $count, $s->{word});
    }
    else
    {
        ok(scalar(@{$s->{suggestions}}) == $count, $s->{word});
    }
}
