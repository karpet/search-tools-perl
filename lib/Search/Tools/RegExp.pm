package Search::Tools::RegExp;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Carp;
use Encode;
use Search::Tools::Keywords;
use Search::Tools::RegExp::Keywords;
use Search::Tools::RegExp::Keyword;
use Search::Tools::XML;

our $VERSION = '0.20';

__PACKAGE__->mk_accessors(
    qw(
        kw
        start_bound
        end_bound
        ),
    @Search::Tools::Accessors
);

my %char2entity = ();
while ( my ( $e, $n ) = each(%Search::Tools::XML::HTML_ents) ) {
    my $char = chr($n);
    $char2entity{$char} = "&$e;";
}
delete $char2entity{"'"};    # only one-way decoding

# Fill in missing entities
for ( 0 .. 255 ) {
    next if exists $char2entity{ chr($_) };
    $char2entity{ chr($_) } = "&#$_;";
}

# this might miss comments inside tags
# or CDATA attributes
# unless HTML::Parser is used
our $TagRE = qr/<[^>]+>/s;

# takes 2x as long to match against the long version
# and perl treats \w equally well against diacritics.
# see example/utf8re.pl
#our $UTF8Char = qr/\p{L}\p{M}*/;
our $UTF8Char = '\w';
our $WordChar = $UTF8Char . quotemeta("'-."); # contractions and compounds ok.
our $IgnFirst = quotemeta("'-");
our $IgnLast  = quotemeta("'-.");
our $PhraseDelim = '"';
our $Wildcard    = '*';

# regexp for what constitutes whitespace in an HTML doc
# it's not as simple as \s|&nbsp; so we define it separately

# NOTE that the pound sign # needs escaping because we use the 'x' flag in our regexp.

my @whitesp = (
    '&\#0020;', '&\#0009;', '&\#000C;', '&\#200B;', '&\#2028;', '&\#2029;',
    '&nbsp;',   '&\#32;',   '&\#160;',  '\s',       '\xa0',     '\x20',
);

our $WhiteSpace = join( '|', @whitesp );

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->{wildcard}          ||= $Wildcard;
    $self->{word_characters}   ||= $WordChar;
    $self->{ignore_first_char} ||= $IgnFirst;
    $self->{ignore_last_char}  ||= $IgnLast;
    $self->{phrase_delim}      ||= $PhraseDelim;

    $self->kw(
        Search::Tools::Keywords->new(
            map { $_ => $self->$_ } @Search::Tools::Accessors
        )
    ) unless $self->kw;

    # a search for a '<' or '>' should still highlight,
    # since &lt; or &gt; can be indexed as literal < and >
    # but this causes a great deal of hassle
    # so we just ignore them.
    $self->{word_characters} =~ s,[<>&],,g;

    # what's the boundary between a word and a not-word?
    # by default:
    #	the beginning of a string
    #	the end of a string
    #	whatever we've defined as WhiteSpace
    #	any character that is not a WordChar
    #   any character we explicitly ignore at start or end of word
    #
    # the \A and \Z (beginning and end) should help if the word butts up
    # against the beginning or end of a tagset
    # like <p>Word or Word</p>

    my @start_bound = (
        '\A',
        '[>]',
        '(?:&[\w\#]+;)',    # because a ; might be a legitimate wordchar
                            # and we treat a char entity like a single char.
                            # if &char; resolves to a legit wordchar
                            # this might give unexpected results.
                            # NOTE that &nbsp; etc is in $WhiteSpace
        $WhiteSpace,
        '[^' . $self->{word_characters} . ']',
        qr/[$self->{ignore_first_char}]+/i
    );

    my @end_bound = (
        '\Z', '[<&]', $WhiteSpace,
        '[^' . $self->{word_characters} . ']',
        qr/[$self->{ignore_last_char}]+/i
    );

    $self->{start_bound} ||= join( '|', @start_bound );

    $self->{end_bound} ||= join( '|', @end_bound );

    # the whitespace in a query phrase might be:
    #	any ignore_last_char, followed by
    #	one or more nonwordchar or whitespace, followed by
    #	any ignore_first_char
    # define for both text and html

    $self->{text_phrase_bound} = join '', qr/[$self->{ignore_last_char}]*/i,
        qr/[\s\x20]|[^$self->{word_characters}]/is, '+',
        qr/[$self->{ignore_first_char}]*/i;
    $self->{html_phrase_bound} = join '', qr/[$self->{ignore_last_char}]*/i,
        qr/$WhiteSpace|[^$self->{word_characters}]/is, '+',
        qr/[$self->{ignore_first_char}]*/i;

}

sub isHTML { $_[1] =~ m/[<>]|&[#\w]+;/ }

sub build {
    my $self = shift;
    my $query = shift or croak "need query to build() RegExp object";

    my $q_array  = [ $self->kw->extract($query) ];
    my $q2regexp = {};

    for my $q (@$q_array) {
        my ( $plain, $html ) = $self->_build($q);
        $q2regexp->{$q} = Search::Tools::RegExp::Keyword->new(
            plain  => $plain,
            html   => $html,
            word   => $q,
            phrase => $q =~ m/\ / ? 1 : 0
        );

    }

    my $kw = Search::Tools::RegExp::Keywords->new(
        hash        => $q2regexp,
        array       => $q_array,
        kw          => $self->kw,
        start_bound => $self->start_bound,
        end_bound   => $self->end_bound,
        map { $_ => $self->$_ } @Search::Tools::Accessors
    );

    return $kw;
}

sub _build {
    my $self      = shift;
    my $q         = shift or croak "need query to build()";
    my $wild      = $self->word_characters;
    my $st_bound  = $self->{start_bound};
    my $end_bound = $self->{end_bound};
    my $wc        = $self->word_characters;
    my $tpb       = $self->{text_phrase_bound};
    my $hpb       = $self->{html_phrase_bound};
    my $wildcard  = $self->wildcard;
    my $wild_esc  = quotemeta($wildcard);

    # define simple pattern for plain text
    # and complex pattern for HTML markup
    my ( $plain, $html );
    my $escaped = quotemeta($q);
    $escaped =~ s/\\[$wild_esc]/[$wc]*/g;    # wildcard
    $escaped =~ s/\\[\s]/$tpb/g;             # whitespace

    $plain = qr/
(
\A|$tpb
)
(
${escaped}
)
(
\Z|$tpb
)
/xis;

    my (@char) = split( m//, $q );

    my $counter = -1;

CHAR: foreach my $c (@char) {
        $counter++;

        my $ent = $char2entity{$c} || carp "no entity defined for >$c< !\n";
        my $num = ord($c);

        # if this is a special regexp char, protect it
        $c = quotemeta($c);

        # if it's a *, replace it with the Wild class
        $c = "[$wild]*" if $c eq $wild_esc;

        if ( $c eq '\ ' ) {
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
    my $safe = join( "\n", @char );   # use \n to make it legible in debugging

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

    return ( $plain, $html );
}

1;
__END__

=pod

=head1 NAME

Search::Tools::RegExp - build regular expressions from search queries

=head1 SYNOPSIS

 my $regexp = Search::Tools::RegExp->new();
 
 my $kw = $regexp->build('the quick brown fox');
 
 for my $w ($kw->keywords)
 {
    my $r = $kw->re( $w );
    
    # the word itself
    printf("the word is %s\n", $r->word);
    
    # is it flagged as a phrase?
    print "the word is a phrase\n" if $r->phrase;
    
    # each of these are regular expressions
    print $r->plain;
    print $r->html;
 }
 

=head1 DESCRIPTION

Build regular expressions for a string of text.

All text is converted to UTF-8 automatically if it isn't already,
via the Search:Tools::Keywords module.


=head1 VARIABLES

The following package variables are defined:

=over

=item UTF8Char

Regexp defining a valid UTF-8 word character. Default C<\w>.

=item WordChar

Default word_characters regexp. Defaults to C<UTF8Char> plus C<'>, C<.> and C<->.

=item IgnFirst

Default ignore_first_char regexp. Defaults to C<'> and C<->.

=item IgnLast

Default ignore_last_char regexp. Defaults to C<'>, C<.> and C<->.

=item PhraseDelim

Phrase delimiter character. Default is double-quote '"'.

=item Wildcard

Character to use as a wildcard. Default is asterik '*'.

=back


=head1 METHODS

=head2 new

Create new object. The following parameters are also accessors:

=over

=item kw

A Search::Tools::Keywords object, if you want to pass in one instead of having
one made for you.

=item wildcard

The wildcard character. Default is C<$Wildcard>.

=item word_characters

Regexp for what characters constitute a 'word'. Default is C<$WordChar>.

=item ignore_first_char

Default is C<$IgnFirst>.

=item ignore_last_char

Default is C<$IgnLast>.

=item stemmer

Stemming code ref passed through to the default Search::Tools::Keywords object.

=item phrase_delim

Phrase delimiter. Defaults to C<$PhraseDelim>.

=item stopwords

Words to be ignored.

=item debug

Turn on helpful info on stderr.

=back

=head2 isHTML( I<str> )

Returns true if I<str> contains anything that looks like HTML markup: 

 < > or &[#\w]+;

This is a naive check but useful for internal purposes.

=head2 build( I<str> )

Returns a Search::Tools::RegExp::Keywords object.


=head1 BUGS and LIMITATIONS

The special HTML chars &, < and > can pose problems in regexps against markup, so they
are ignored if you include them in C<word_characters> in new().

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
