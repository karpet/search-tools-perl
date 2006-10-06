package Search::Tools::Keywords;

use 5.008;
use strict;
use warnings;

# make sure we get correct ->utf8 encoding
use POSIX qw(locale_h);
use locale;

use Carp;
use Data::Dump qw/ pp /;    # just for debugging
use Encode;
use Search::Tools;
use Search::Tools::RegExp;
use Search::Tools::Transliterate;

use Search::QueryParser;

use base qw( Class::Accessor::Fast );

our $VERSION = '0.02';

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
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
        qw(
          and_word
          or_word
          not_word
          locale
          charset
          ),
        @Search::Tools::Accessors
    );

    $self->{locale}  ||= setlocale(LC_CTYPE);
    $self->{charset} ||= ($self->{locale} =~ m/^.+?\.(.+)/ || 'iso-8859-1');

    $self->{debug} ||= $ENV{PERL_DEBUG} || 0;

}

sub _make_utf8
{
    my $self = shift;
    my $str  = shift;

    # simple byte check first
    if (Search::Tools::Transliterate->is_valid_utf8($str))
    {
        Encode::_utf8_on($str);
        return $str;
    }

    # make sure our query is really UTF-8
    if (!Encode::is_utf8($str))
    {

        #carp "converting $str from " . $self->charset . " -> utf8";
        Encode::from_to($str, $self->charset, 'utf8');
    }
    return $str;
}

sub extract
{
    my $self      = shift;
    my $query     = shift or croak "need query to extract keywords";
    my $stopwords = $self->stopwords || [];
    my $and_word  = $self->and_word || 'and';
    my $or_word   = $self->or_word || 'or';
    my $not_word  = $self->not_word || 'not';
    my $wildcard  = $self->wildcard || '*';
    my $phrase    = $self->phrase_delim || '"';
    my $igf       = $self->ignore_first_char
      || $Search::Tools::RegExp::IgnFirst;
    my $igl = $self->ignore_last_char || $Search::Tools::RegExp::IgnLast;
    my $wordchar = $self->word_characters
      || $Search::Tools::RegExp::WordChar;

    my $esc_wildcard = quotemeta($wildcard);

    my $word_re = qr/([$wordchar]+($esc_wildcard)?)/;

    my @query = @{ref $query ? $query : [$query]};
    $stopwords = [split(/\s+/, $stopwords)] unless ref $stopwords;
    my %stophash = map { $self->_make_utf8(lc($_)) => 1 } @$stopwords;

    my (%words, %uniq, $c);

    my $parser =
      Search::QueryParser->new(
                               rxAnd => qr{$and_word}i,
                               rxOr  => qr{$or_word}i,
                               rxNot => qr{$not_word}i,
                              );

  Q: for my $q (@query)
    {
        my $p = $parser->parse($self->_make_utf8($q), 1);
        $self->debug && carp "parsetree: " . pp($p);
        $self->_get_v(\%uniq, $p, $c);
    }

    $self->debug && carp "parsed: " . pp(\%uniq);

    my $count = scalar(keys %uniq);

    # parse uniq into word tokens
    # including removing stop words

    $self->debug && carp "word_re: $word_re";

  U: for my $u (sort { $uniq{$a} <=> $uniq{$b} } keys %uniq)
    {

        my $n = $uniq{$u};

        # only phrases have space
        # but due to our word_re, a single non-spaced string
        # might actually be multiple word tokens
        my $isphrase = $u =~ m/\s/;
        
        $self->debug && carp "$u -> isphrase";

        my @w = ();

      TOK: for my $w (split(m/\s+/, $self->_make_utf8($u)))
        {

            next TOK unless $w =~ m/\S/;

            $w =~ s/\Q$phrase\E//g;

            while ($w =~ m/$word_re/g)
            {
                my $tok = $1;

                # strip ignorable chars
                $tok =~ s/^[$igf]+//;
                $tok =~ s/[$igl]+$//;

                unless ($tok)
                {
                    $self->debug && carp "no token for '$w' $word_re";
                    next TOK;
                }

                $self->debug && carp "found token: $tok";

                if (exists $stophash{lc($tok)})
                {
                    $self->debug && carp "$tok = stopword";
                    next TOK unless $isphrase;
                }

                unless ($isphrase)
                {
                    next TOK if lc($tok) eq lc($or_word);
                    next TOK if lc($tok) eq lc($and_word);
                    next TOK if lc($tok) eq lc($not_word);
                }

                # final sanity check
                if (!Encode::is_utf8($tok))
                {
                    carp "$tok is NOT utf8";
                    next TOK;
                }

                #$self->debug && carp "pushing $tok into wordlist";
                push(@w, $tok);

            }

        }

        next U unless @w;

        #$self->debug && carp "joining \@w: " . pp(\@w);
        if ($isphrase)
        {
            $words{join(' ', @w)} = $n + $count++;
        }
        else
        {
            for (@w)
            {
                $words{$_} = $n + $count++;
            }
        }

    }

    $self->debug && carp "tokenized: " . pp(\%words);

    # make sure we don't have 'foo' and 'foo*'
    for (keys %words)
    {
        if ($_ =~ m/$esc_wildcard/)
        {
            (my $copy = $_) =~ s,$esc_wildcard,,g;

            # delete the more exact of the two
            # since the * will match both
            delete($words{$copy});
        }
    }

    $self->debug && carp "wildcards removed: " . pp(\%words);

    # if any words need to be stemmed
    if ($self->stemmer)
    {

        # split each $word into words
        # stem each word
        # if stem ne word, break into chars and find first N common
        # rejoin $uniq

        #carp "stemming ON\n";

      K: for (keys %words)
        {
            my (@w) = split /\s+/;
          W: for my $w (@w)
            {
                my $func = $self->stemmer;
                my $f    = &$func($self, $w);

                #warn "w: $w\nf: $f\n";

                if ($f ne $w)
                {

                    my @stemmed = split //, $f;
                    my @char    = split //, $w;
                    $f = '';    #reset
                    while (@char && @stemmed && $stemmed[0] eq $char[0])
                    {
                        $f .= shift @stemmed;
                        shift @char;
                    }

                }

                # add wildcard to indicate chars were lost
                $w = $f . $wildcard;
            }
            my $new = join ' ', @w;
            if ($new ne $_)
            {
                $words{$new} = $words{$_};
                delete $words{$_};
            }
        }

    }

    $self->debug && carp "stemming done: " . pp(\%words);

    # sort keeps query in same order as we entered
    return (sort { $words{$a} <=> $words{$b} } keys %words);

}

sub _get_v
{
    my $self      = shift;
    my $uniq      = shift;
    my $parseTree = shift;
    my $c         = shift;

    # we only want the values from non minus queries
    for my $node (grep { $_ eq '+' || $_ eq '' } keys %$parseTree)
    {
        my @branches = @{$parseTree->{$node}};

        for my $leaf (@branches)
        {
            my $v = $leaf->{value};

            if (ref $v)
            {
                $self->_get_v($uniq, $v, $c);
            }
            else
            {

                # collapse any whitespace
                $v =~ s,\s+,\ ,g;

                $uniq->{$v} = ++$c;
            }
        }
    }

}

1;

__END__

=pod

=head1 NAME

Search::Tools::Keywords - extract keywords from a search query

=head1 SYNOPSIS

 use Search::Tools::Keywords;
 use Search::Tools::RegExp;
 
 my $query = 'the quick fox color:brown and "lazy dog" not jumped';
 
 my $kw = Search::Tools::Keywords->new(
            stopwords           => 'the',
            and_word            => 'and',
            or_word             => 'or',
            not_word            => 'not',
            stemmer             => &your_stemmer_here,       
            ignore_first_char   => '\+\-',
            ignore_last_char    => '',
            word_characters     => $Search::Tools::RegExp::WordChar,
            debug               => 0,
            phrase_delim        => '"'
            );
            
 my @words = $kw->extract( $query );
 # returns:
 #   quick
 #   fox
 #   brown
 #   lazy dog
 
 
=head1 DESCRIPTION

B<Do not confuse this class with Search::Tools::RegExp::Keywords.>

Search::Tools::Keywords extracts the meaningful words from a search
query. Since many search engines support a syntax that includes special
characters, boolean words, stopwords, and fields, search queries can become
complicated. In order to separate the wheat from the chafe, the supporting
words and symbols are removed and just the actual search terms (keywords)
are returned.

This class is used internally by Search::Tools::RegExp. You probably don't need
to use it directly. But if you do, read on.

=head1 METHODS

=head2 new( %opts )

The new() method instantiates a S::T::K object. With the exception
of extract(), all the following methods can be passed as key/value
pairs in new().
 
=head2 extract( I<query> )

The extract method parses I<query> and returns an array of meaningful words.
I<query> can either be a scalar string or an array reference (if multiple queries
should be parsed simultaneously).

Only positive words are extracted. In other words, if you search for:

 foo not bar
 
then only C<foo> is returned. Likewise:

 +foo -bar
 
would return only C<foo>.

B<NOTE:> All queries are converted to UTF-8. See the C<charset> param.

=head2 stemmer

The stemmer function is used to find the root 'stem' of a word. There are many
stemming algorithms available, including many on CPAN. The stemmer function
should expect to receive two parameters: the Keywords object and the word to be
stemmed. It should return exactly one value: the stemmed word.

Example stemmer function:

 use Lingua::Stem;
 my $stemmer = Lingua::Stem->new;
 
 sub mystemfunc
 {
     my ($kw,$word) = @_;
     return $stemmer->stem($word)->[0];
 }
 
 # and pass to Keywords new() method:
 
 my $keyword_obj = Search::Tools::Keyword->new(stemmer => \&mystemfunc);
     
=head2 stopwords

A list of common words that should be ignored in parsing out keywords. 
May be either a string that will be split on whitespace, or an array ref.

B<NOTE:> If a stopword is contained in a phrase, then the phrase 
will be tokenized into words based on whitespace, then the stopwords removed.

=head2 ignore_first_char

String of characters to strip from the beginning of all words.

=head2 ignore_last_char

String of characters to strip from the end of all words.

=head2 and_word

Default: C<and>

=head2 or_word

Default: C<or>

=head2 not_word

Default: C<not>

=head2 wildcard

Default: C<*>

=head2 locale

Set a locale explicitly for a Keywords object. The C<charset> value is extracted
from the locale. If not set, the locale is inherited from the C<LC_CTYPE> environment
variable.

=head2 charset

Base charset used for converting queries to UTF-8. If not set, extracted from C<locale>.

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

HTML::HiLiter, Search::QueryParser
