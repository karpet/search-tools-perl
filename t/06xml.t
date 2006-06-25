use Test::More tests => 5;

BEGIN
{
    use_ok('Search::Tools::XML');
}

my $class = 'Search::Tools::XML';

my $text = 'the "quick brown" fox';

my $xml = $class->start_tag('foo');

$xml .= $class->utf8_safe($text);

$xml .= $class->end_tag('foo');

is($xml, '<foo>the &#34;quick brown&#34; fox</foo>',    "xml");

$class->escape($xml);

is($xml, '&lt;foo&gt;the &amp;#34;quick brown&amp;#34; fox&lt;/foo&gt;',    "esc");

$class->unescape($xml);

is($xml, '<foo>the "quick brown" fox</foo>',    "unesc");

my $plain = $class->no_html($xml);

is($plain, $text,   "there and back again");
