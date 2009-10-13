use Test::More tests => 8;
use Data::Dump;

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

$xml = $class->escape($xml);

is($xml, '&lt;foo&gt;the &amp;#34;quick brown&amp;#34; fox&lt;/foo&gt;',    "esc");

$xml = $class->unescape($xml);

is($xml, '<foo>the "quick brown" fox</foo>',    "unesc");

my $plain = $class->no_html($xml);

is($plain, $text,   "there and back again");

# control chars
my $lowchars = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20";
my $lowesc   = "         \t\n  \r                   ";
my $utf8_safe = $class->utf8_safe($lowchars);
is($utf8_safe, $lowesc, "utf8_safe with low chars");
#Data::Dump::dump($utf8_safe);
#Data::Dump::dump($lowesc);

# attributes
ok( my $xml_w_attr = $class->start_tag('foo', { bar => '"><& chars' }),
    "xml with attr");
is( $xml_w_attr, '<foo bar="&quot;&gt;&lt;&amp; chars">', "start tag with attr");
 
