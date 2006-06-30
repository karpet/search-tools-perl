package Search::Tools::RegExp;

use 5.008;
use strict;
use warnings;
use Carp;
use Encode;
use Search::Tools::Keywords;
use Search::Tools::RegExp::Keywords;
use Search::Tools::RegExp::Keyword;
use Search::Tools::XML;

use base qw( Class::Accessor::Fast );

our $VERSION = '0.01';

my %char2entity = ();
while (my ($e, $n) = each(%Search::Tools::XML::HTML_ents))
{
    my $char = chr($n);
    $char2entity{$char} = "&$e;";
}
delete $char2entity{"'"};    # only one-way decoding

# Fill in missing entities
for (0 .. 255)
{
    next if exists $char2entity{chr($_)};
    $char2entity{chr($_)} = "&#$_;";
}

# this might miss comments inside tags
# or CDATA attributes
# unless HTML::Parser is used
our $TagRE = qr/<[^>]+>/s;

# takes 2x as long to match a real utf8 char but that's the cost of being more thorough
our $UTF8Char = qr/\p{L}\p{M}*/;

#our $UTF8Char = '\w';

our $WordChar    = "$UTF8Char./-";
our $BegChar     = "$UTF8Char./-";
our $EndChar     = $UTF8Char;
our $PhraseDelim = '"';

# regexp for what constitutes whitespace in an HTML doc
# it's not as simple as \s|&nbsp; so we define it separately

# NOTE that the pound sign # seems to need escaping, though that seems like a perl bug to me.
# Mon Sep 20 11:34:04 CDT 2004

my @whitesp = (
               '&\#0020;', '&\#0009;', '&\#000C;', '&\#200B;',
               '&\#2028;', '&\#2029;', '&nbsp;',   '&\#32;',
               '&\#160;',  '\s',       '\xa0',     '\x20',
              );

our $WhiteSpace = join('|', @whitesp);

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

    $self->mk_accessors(
        qw/
          kw
          kw_opts
          wildcard
          word_characters
          begin_characters
          end_characters
          start_bound
          end_bound
          ignore_first_char
          ignore_last_char
          stemmer

          /
    );

    $self->{wildcard} ||= $self->{kw_opts}->{wildcard} || '*';
    $self->{word_characters}  ||= $WordChar;
    $self->{end_characters}   ||= $EndChar;
    $self->{begin_characters} ||= $BegChar;

    $self->kw(
              Search::Tools::Keywords->new(
                          %{
                              $self->kw_opts
                                || {
                                  ignore_first_char => $self->ignore_first_char,
                                  ignore_last_char  => $self->ignore_last_char,
                                  wildcard          => $self->wildcard,
                                  stemmer           => $self->stemmer,
                                  word_characters   => $self->word_characters,
                                  begin_characters  => $self->begin_characters,
                                  end_characters    => $self->end_characters
                                }
                            }
              )
             )
      unless $self->kw;

    # a search for a '<' or '>' should still highlight,
    # since &lt; or &gt; can be indexed as literal < and >
    # but this causes a great deal of hassle
    # so we just ignore them.
    for (qw(word_characters end_characters begin_characters))
    {
        $self->{$_} =~ s,[<>&],,g;
    }

    # what's the boundary between a word and a not-word?
    # by default:
    #	the beginning of a string
    #	the end of a string
    #	whatever we've defined as WhiteSpace
    #	any character that is not a WordChar
    #
    # the \A and \Z (beginning and end) should help if the word butts up
    # against the beginning or end of a tagset
    # like <p>Word or Word</p>

    $self->{start_bound} ||= join(
        '|',
        '\A',
        '[>]',
        '(?:&[\w\#]+;)',    # because a ; might be a legitimate wordchar
                            # and we treat a char entity like a single char.
                            # if &char; resolves to a legit wordchar
                            # this might give unexpected results.
                            # NOTE that &nbsp; etc is in $WhiteSpace
        $WhiteSpace,
        '[^' . $self->begin_characters . ']'
                                 );

    $self->{end_bound} ||=
      join('|', '\Z', '[<&]', $WhiteSpace, '[^' . $self->end_characters . ']');

    # the whitespace in a query phrase might be:
    #	any ignore_last_char, followed by
    #	one or more nonwordchar or whitespace, followed by
    #	any ignore_first_char
    # define for both text and html

    my $igf =
      $self->ignore_first_char ? qr/[$self->{ignore_first_char}]*/i : '';
    my $igl = $self->ignore_last_char ? qr/[$self->{ignore_last_char}]*/i : '';

    $self->{text_phrase_bound} = join '', $igl,
      qr/[\s\x20]|[^$self->{word_characters}]/is, '+', $igf;
    $self->{html_phrase_bound} = join '', $igl,
      qr/$WhiteSpace|[^$self->{word_characters}]/is, '+', $igf;

}

sub isHTML { $_[1] =~ m/[<>]|&[#\w]+;/ }

sub build
{
    my $self  = shift;
    my $query = shift or croak "need query to build() RegExp object";

    my $q_array  = [$self->kw->extract($query)];
    my $q2regexp = {};

    for my $q (@$q_array)
    {
        my ($plain, $html) = $self->_build($q);
        $q2regexp->{$q} =
          Search::Tools::RegExp::Keyword->new(
                                              plain => $plain,
                                              html  => $html,
                                              word  => $q
                                             );

    }

    my $kw =
      Search::Tools::RegExp::Keywords->new(
                                  hash              => $q2regexp,
                                  array             => $q_array,
                                  wildcard          => $self->wildcard,
                                  word_characters   => $self->word_characters,
                                  begin_characters  => $self->begin_characters,
                                  end_characters    => $self->end_characters,
                                  ignore_first_char => $self->ignore_first_char,
                                  ignore_last_char  => $self->ignore_last_char,
                                  start_bound       => $self->start_bound,
                                  end_bound         => $self->end_bound,
                                  kw                => $self->kw,
      );

    return $kw;
}

sub _build
{
    my $self      = shift;
    my $q         = shift or croak "need query to build()";
    my $wild      = $self->{end_characters};
    my $begchars  = $self->{begin_characters};
    my $st_bound  = $self->{start_bound};
    my $end_bound = $self->{end_bound};
    my $wc        = $self->{word_characters};
    my $tpb       = $self->{text_phrase_bound};
    my $hpb       = $self->{html_phrase_bound};
    my $wildcard  = $self->wildcard;
    my $wild_esc  = quotemeta($wildcard);

    # define simple pattern for plain text
    # and complex pattern for HTML markup
    my ($plain, $html);
    my $escaped = quotemeta($q);
    $escaped =~ s/\\[$wild_esc]/[$wc]*/g;    # wildcard
    $escaped =~ s/\\[\s]/$tpb/g;             # whitespace

    $plain = qr/
(
\A|[^$begchars]
)
(
${escaped}
)
(
[^$wild]|\Z
)
/xis;

    my (@char) = split(//, $q);

    my $counter = -1;

  CHAR: foreach my $c (@char)
    {
        $counter++;

        my $ent = $char2entity{$c} || carp "no entity defined for >$c< !\n";
        my $num = ord($c);

        # if this is a special regexp char, protect it
        $c = quotemeta($c);

        # if it's a *, replace it with the Wild class
        $c = "[$wild]*" if $c eq $wild_esc;

        if ($c eq '\ ')
        {
            $c = $hpb . $TagRE . '*';
            next CHAR;
        }

        my $aka = $ent eq "&#$num;" ? $ent : "$ent|&#$num;";

        # make $c into a regexp
        $c = qr/$c|$aka/i unless $c eq "[$wild]*";

        # any char might be followed by zero or more tags, unless it's the last char
        $c .= $TagRE . '*' unless $counter == $#char;

    }

    # re-join the chars into a single string
    my $safe = join("\n", @char);    # use \n to make it legible in debugging

    # for debugging legibility we include newlines, so make sure we s//x in matches
    $html = qr/
(
${st_bound}
)
(
${safe}
)
(
${end_bound}
)
/xis;

    return ($plain, $html);
}

1;
__END__

=pod

=head1 NAME

Search::Tools::RegExp - build regular expressions from search queries

=head1 SYNOPSIS

 my $re = Search::Tools::RegExp->new();
 
 my $kw = $re->build('the quick brown fox');
 
 for my $w ($kw->keywords)
 {
    my $re = $kw->re( $w );
    
    # each of these are regular expressions
    print $re->plain;
    print $re->html;
 }
 
 
=head1 DESCRIPTION



=head1 METHODS

=head2 new

=head2 isHTML

=head2 build


=head1 VARIABLES


=head1 BUGS and LIMITATIONS

All new() params should be flagged as UTF-8 strings. If you include non-ASCII chars
in your regular expressions, etc., you should convert them first to UTF-8 with the standard
Encode module.

The special HTML chars < and > can pose problems in regexps against markup, so they
are ignored in any regexp params you pass to new().

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

Based on the HTML::HiLiter regular expression building code, originally by the same author, 
copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of this module.

=head1 COPYRIGHT

Copyright 2006 by Peter Karman. 
This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

HTML::HiLiter, Search::Tools, Search::Tools::RegExp::Keywords, Search::Tools::RegExp::Keyword

=cut
