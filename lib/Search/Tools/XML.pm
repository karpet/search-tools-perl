package Search::Tools::XML;

use 5.006;
use strict;
use warnings;
use Carp;
use Search::Tools::RegExp;

our $VERSION = '0.12';

=pod

=head1 NAME

Search::Tools::XML - methods for playing nice with XML and HTML

=head1 SYNOPSIS

 use Search::Tools::XML;
 
 my $class = 'Search::Tools::XML';
 
 my $text = 'the "quick brown" fox';
 
 my $xml = $class->start_tag('foo');
 
 $xml .= $class->utf8_safe( $text );
 
 $xml .= $class->end_tag('foo');
 
 # $xml: <foo>the &#34;quick brown&#34; fox</foo>
 
 $class->escape( $xml );
 
 # $xml: &lt;foo&gt;the &amp;#34;quick brown&amp;#34; fox&lt;/foo&gt;
 
 $class->unescape( $xml );
 
 # $xml: <foo>the "quick brown" fox</foo>
 
 my $plain = $class->no_html( $xml );
 
 # $plain eq $text
 
 
=head1 DESCRIPTION

Search::Tools::XML provides utility methods for dealing with XML and HTML.
There isn't really anything new here that CPAN doesn't provide via HTML::Entities
or similar modules. The difference is convenience: the most common methods you
need for search apps are in one place with no extra dependencies.

B<NOTE:> To get full UTF-8 character set from chr() you must be using Perl >= 5.8.
This affects things like the unescape* methods.

=head1 VARIABLES

=head2 %Ents

Basic HTML/XML characters that must be escaped:

 '>' => '&gt;',
 '<' => '&lt;',
 '&' => '&amp;',
 '"' => '&quot;',
 "'" => '&apos;'
 
=head2 %HTML_ents

Complete map of all named HTML entities to their decimal values.

=cut

our %Ents = (
             '>' => '&gt;',
             '<' => '&lt;',
             '&' => '&amp;',
             '"' => '&quot;',
             "'" => '&apos;'
            );
my $ToEscape = join('', keys %Ents);

# HTML entity table
# this just removes a dependency on another module...

our %HTML_ents = (
                  quot     => 34,
                  amp      => 38,
                  apos     => 39,
                  'lt'     => 60,
                  'gt'     => 62,
                  nbsp     => 160,
                  iexcl    => 161,
                  cent     => 162,
                  pound    => 163,
                  curren   => 164,
                  yen      => 165,
                  brvbar   => 166,
                  sect     => 167,
                  uml      => 168,
                  copy     => 169,
                  ordf     => 170,
                  laquo    => 171,
                  not      => 172,
                  shy      => 173,
                  reg      => 174,
                  macr     => 175,
                  deg      => 176,
                  plusmn   => 177,
                  sup2     => 178,
                  sup3     => 179,
                  acute    => 180,
                  micro    => 181,
                  para     => 182,
                  middot   => 183,
                  cedil    => 184,
                  sup1     => 185,
                  ordm     => 186,
                  raquo    => 187,
                  frac14   => 188,
                  frac12   => 189,
                  frac34   => 190,
                  iquest   => 191,
                  Agrave   => 192,
                  Aacute   => 193,
                  Acirc    => 194,
                  Atilde   => 195,
                  Auml     => 196,
                  Aring    => 197,
                  AElig    => 198,
                  Ccedil   => 199,
                  Egrave   => 200,
                  Eacute   => 201,
                  Ecirc    => 202,
                  Euml     => 203,
                  Igrave   => 204,
                  Iacute   => 205,
                  Icirc    => 206,
                  Iuml     => 207,
                  ETH      => 208,
                  Ntilde   => 209,
                  Ograve   => 210,
                  Oacute   => 211,
                  Ocirc    => 212,
                  Otilde   => 213,
                  Ouml     => 214,
                  'times'  => 215,
                  Oslash   => 216,
                  Ugrave   => 217,
                  Uacute   => 218,
                  Ucirc    => 219,
                  Uuml     => 220,
                  Yacute   => 221,
                  THORN    => 222,
                  szlig    => 223,
                  agrave   => 224,
                  aacute   => 225,
                  acirc    => 226,
                  atilde   => 227,
                  auml     => 228,
                  aring    => 229,
                  aelig    => 230,
                  ccedil   => 231,
                  egrave   => 232,
                  eacute   => 233,
                  ecirc    => 234,
                  euml     => 235,
                  igrave   => 236,
                  iacute   => 237,
                  icirc    => 238,
                  iuml     => 239,
                  eth      => 240,
                  ntilde   => 241,
                  ograve   => 242,
                  oacute   => 243,
                  ocirc    => 244,
                  otilde   => 245,
                  ouml     => 246,
                  divide   => 247,
                  oslash   => 248,
                  ugrave   => 249,
                  uacute   => 250,
                  ucirc    => 251,
                  uuml     => 252,
                  yacute   => 253,
                  thorn    => 254,
                  yuml     => 255,
                  OElig    => 338,
                  oelig    => 339,
                  Scaron   => 352,
                  scaron   => 353,
                  Yuml     => 376,
                  fnof     => 402,
                  circ     => 710,
                  tilde    => 732,
                  Alpha    => 913,
                  Beta     => 914,
                  Gamma    => 915,
                  Delta    => 916,
                  Epsilon  => 917,
                  Zeta     => 918,
                  Eta      => 919,
                  Theta    => 920,
                  Iota     => 921,
                  Kappa    => 922,
                  Lambda   => 923,
                  Mu       => 924,
                  Nu       => 925,
                  Xi       => 926,
                  Omicron  => 927,
                  Pi       => 928,
                  Rho      => 929,
                  Sigma    => 931,
                  Tau      => 932,
                  Upsilon  => 933,
                  Phi      => 934,
                  Chi      => 935,
                  Psi      => 936,
                  Omega    => 937,
                  alpha    => 945,
                  beta     => 946,
                  gamma    => 947,
                  delta    => 948,
                  epsilon  => 949,
                  zeta     => 950,
                  eta      => 951,
                  theta    => 952,
                  iota     => 953,
                  kappa    => 954,
                  lambda   => 955,
                  mu       => 956,
                  nu       => 957,
                  xi       => 958,
                  omicron  => 959,
                  pi       => 960,
                  rho      => 961,
                  sigmaf   => 962,
                  sigma    => 963,
                  tau      => 964,
                  upsilon  => 965,
                  phi      => 966,
                  chi      => 967,
                  psi      => 968,
                  omega    => 969,
                  thetasym => 977,
                  upsih    => 978,
                  piv      => 982,
                  ensp     => 8194,
                  emsp     => 8195,
                  thinsp   => 8201,
                  zwnj     => 8204,
                  zwj      => 8205,
                  lrm      => 8206,
                  rlm      => 8207,
                  ndash    => 8211,
                  mdash    => 8212,
                  lsquo    => 8216,
                  rsquo    => 8217,
                  sbquo    => 8218,
                  ldquo    => 8220,
                  rdquo    => 8221,
                  bdquo    => 8222,
                  dagger   => 8224,
                  Dagger   => 8225,
                  bull     => 8226,
                  hellip   => 8230,
                  permil   => 8240,
                  prime    => 8242,
                  Prime    => 8243,
                  lsaquo   => 8249,
                  rsaquo   => 8250,
                  oline    => 8254,
                  frasl    => 8260,
                  euro     => 8364,
                  image    => 8465,
                  weierp   => 8472,
                  real     => 8476,
                  trade    => 8482,
                  alefsym  => 8501,
                  larr     => 8592,
                  uarr     => 8593,
                  rarr     => 8594,
                  darr     => 8595,
                  harr     => 8596,
                  crarr    => 8629,
                  lArr     => 8656,
                  uArr     => 8657,
                  rArr     => 8658,
                  dArr     => 8659,
                  hArr     => 8660,
                  forall   => 8704,
                  part     => 8706,
                  exist    => 8707,
                  empty    => 8709,
                  nabla    => 8711,
                  isin     => 8712,
                  notin    => 8713,
                  ni       => 8715,
                  prod     => 8719,
                  'sum'    => 8721,
                  'minus'  => 8722,
                  lowast   => 8727,
                  radic    => 8730,
                  prop     => 8733,
                  infin    => 8734,
                  ang      => 8736,
                  'and'    => 8743,
                  'or'     => 8744,
                  cap      => 8745,
                  cup      => 8746,
                  int      => 8747,
                  there4   => 8756,
                  sim      => 8764,
                  cong     => 8773,
                  asymp    => 8776,
                  ne       => 8800,
                  equiv    => 8801,
                  le       => 8804,
                  ge       => 8805,
                  sub      => 8834,
                  sup      => 8835,
                  nsub     => 8836,
                  sube     => 8838,
                  supe     => 8839,
                  oplus    => 8853,
                  otimes   => 8855,
                  perp     => 8869,
                  sdot     => 8901,
                  lceil    => 8968,
                  rceil    => 8969,
                  lfloor   => 8970,
                  rfloor   => 8971,
                  lang     => 9001,
                  rang     => 9002,
                  loz      => 9674,
                  spades   => 9824,
                  clubs    => 9827,
                  hearts   => 9829,
                  diams    => 9830,
                 );

=head1 METHODS

The following methods may be accessed either as object or class methods.

=head2 new

Create a Search::Tools::XML object.

=cut

sub new
{
    my $class = shift;
    my $self  = {};
    bless($self, $class);
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self  = shift;
    my %extra = @_;
    @$self{keys %extra} = values %extra;
}

=head2 start_tag( I<string> )

=head2 end_tag( I<string> )

Returns I<string> as a tag, either start or end. I<string> will be escaped for any non-valid
chars using tag_safe().

=cut

sub start_tag { "<" . $_[0]->tag_safe($_[1]) . ">" }
sub end_tag   { "</" . $_[0]->tag_safe($_[1]) . ">" }

=pod

=head2 tag_safe( I<string> )

Create a valid XML tag name, escaping/omitting invalid characters.

Example:

	my $tag = Search::Tools::XML->tag_safe( '1 * ! tag foo' );
    # $tag == '______tag_foo'

=cut

sub tag_safe
{
    my $class = shift;
    my $t     = shift;

    return '_' unless length $t;

    $t =~ s/[^-\.\w]/_/g;
    $t =~ s/^(\d)/_$1/;

    return $t;
}

=pod

=head2 utf8_safe( I<string> )

Return I<string> with special XML chars and all
non-ASCII chars converted to numeric entities.

This is escape() on steroids. B<Do not use them both on the same text>
unless you know what you're doing. See the SYNOPSIS for an example.

=cut

sub utf8_safe
{
    my $class = shift;
    my $t     = shift;
    $t = '' unless defined $t;

    #$t =~ s,[\x00-\x1f],\n,g;    # converts all low chars to LF

    $t =~ s{([^\x20\x21\x23-\x25\x28-\x3b\x3d\x3F-\x5B\x5D-\x7E])}
            {'&#'.(ord($1)).';'}eg;

    return $t;
}

=head2 no_html( I<text> )

no_html() is a brute-force method for removing all tags and entities
from I<text>. A simple regular expression is used, so things like
nested comments and the like will probably break. If you really
need to reliably filter out the tags and entities from a HTML text, use
HTML::Parser or similar.

I<text> is returned with no markup in it.

=cut

sub no_html
{
    my $class = shift;
    my $text  = shift or croak "need text to strip HTML from";

    $text =~ s,$Search::Tools::RegExp::TagRE,,g;

    $class->unescape($text);

    return $text;
}

=head2 escape( I<text> )

Similar to escape() functions in more famous CPAN modules, but without the added
dependency. escape() will convert the special XML chars (><'"&) to their
entity equivalents. See %Ents.

I<text> is modified in place.

=cut

sub escape { $_[1] =~ s/([$ToEscape])/$Ents{$1}/og if defined($_[1]) }

=head2 unescape( I<text> )

Similar to unescape() functions in more famous CPAN modules, but without the added
dependency. unescape() will convert all entities to their chr() equivalents.

B<NOTE:> unescape() does more than reverse the effects of escape(). It attempts
to resolve B<all> entities, not just the special XML entities (><'"&).

B<NOTE:> 

I<text> is modified in place.

=cut

sub unescape
{
    if (defined $_[0])
    {
        $_[0]->unescape_named($_[1]);
        $_[0]->unescape_decimal($_[1]);
    }
    return $_[1];
}

=head2 unescape_named

Replace all named HTML entities with their chr() equivalents.

=cut

sub unescape_named
{
    if (defined($_[1]))
    {

        # named entities - check first to see if it is worth looping
        if ($_[1] =~ m/&[a-zA-Z]+;/)
        {
            for (keys %HTML_ents)
            {
                my $n = $HTML_ents{$_};
                $_[1] =~ s/&$_;/chr($n)/eg;
            }
        }
    }
    return $_[1];
}

=head2 unescape_decimal

Replace all decimal entities with their chr() equivalents.

=cut

sub unescape_decimal
{

    # resolve numeric entities as best we can
    $_[1] =~ s/&#(\d+);/chr($1)/ego if defined($_[1]);
    return $_[1];
}

1;
__END__


=head1 AUTHOR

Peter Karman C<perl@peknet.com>

Based on the CrayDoc regular expression building code, originally by the same author, 
copyright 2004 by Cray Inc.

=head1 COPYRIGHT

Copyright 2006 by Peter Karman. 
This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools

=cut
