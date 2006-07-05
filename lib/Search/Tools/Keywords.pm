package Search::Tools::Keywords;

use 5.008;
use strict;
use warnings;

# make sure we get correct ->utf8 encoding
use POSIX qw(locale_h);
use locale;

use Carp;
#use Data::Dumper;      # just for debugging
use Encode;
use Search::QueryParser;

use base qw( Class::Accessor::Fast );

our $VERSION = '0.01';

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
          stemmer
          stopwords
          ignore_first_char
          ignore_last_char
          and_word
          or_word
          not_word
          wildcard
          locale
          charset
          /
    );

    $self->{locale}  ||= setlocale(LC_CTYPE);
    $self->{charset} ||= ($self->{locale} =~ m/^.+?\.(.+)/ || 'iso-8859-1');

}

sub _make_utf8
{
    my $self = shift;
    my $str  = shift;

    # make sure our query is UTF-8
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
    my $stopwords = $self->stopwords;
    my $and_word  = $self->and_word || 'and';
    my $or_word   = $self->or_word || 'or';
    my $not_word  = $self->not_word || 'not';
    my $wildcard  = $self->wildcard || '*';
    my $igf       = quotemeta($self->ignore_first_char || '');
    my $igl       = quotemeta($self->ignore_last_char || '');

    my @query = @{ref $query ? $query : [$query]};
    if ($stopwords)
    {
        $stopwords = [split(/\s+/, $stopwords)] unless ref $stopwords;
        $_ = $self->_make_utf8($_) for @$stopwords;
    }
    my $esc_wildcard = quotemeta($wildcard);

    my (%words, %uniq, $c);

    my $parser =
      Search::QueryParser->new(
                               rxAnd => qr{$and_word}i,
                               rxOr  => qr{$or_word}i,
                               rxNot => qr{$not_word}i,
                              );

  Q: for my $q (@query)
    {
        $q = $self->_make_utf8($q);
        my $p = $parser->parse($q, 1);
        $self->_get_v(\%uniq, $p, $c);
    }

    #carp "parsed: " . Dumper(\%uniq);

    my $count = scalar(keys %uniq);
    # remove any stopwords
    # including splitting up phrases
    for my $stop (@$stopwords)
    {
        delete $uniq{$stop};

        for my $u (grep { m/(\A|\ )$stop(\ |\Z)/ } keys %uniq)
        {
            delete $uniq{$u};
            for my $w (split(m/\s+/, $u))
            {
                next if $w =~ m/^(\Q$stop\E|$and_word|$or_word|$not_word)$/i;
                $uniq{$w} = $count++;
            }
        }
    }

    #carp "stopwords: " . Dumper(\%uniq);

    # remove any ignore chars
  W: for my $w (keys %uniq)
    {
        my $before = $w;
        $w =~ s/(\A|\s+)[$igf]*/$1/gi if $igf;
        $w =~ s/[$igl]*(\Z|\s+)/$1/gi if $igl;
        $words{$w} = $uniq{$before};
    }

    #carp "ignorechars: " . Dumper( \%words );

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

    #carp "wildcard: " . Dumper( \%words );

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

    #carp "stemmer: " . Dumper( \%words );

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

 my $query = 'the quick fox color:brown and "lazy dog" not jumped';
 
 my $kw = Search::Tools::Keywords->new(
            stopwords           => 'the',
            and_word            => 'and',
            or_word             => 'or',
            not_word            => 'not',
            stemmer             => &your_stemmer_here,       
            ignore_first_char   => '\+\-',
            ignore_last_char    => ''
            );
            
 my @words = $kw->extract( $query );
 # returns:
 #   quick
 #   fox
 #   brown
 #   lazy dog
 #   jumped
 
 
=head1 DESCRIPTION

B<Do not confuse this class with Search::Tools::RegExp::Keywords.>

Search::Tools::Keywords extracts the meaningful words from a search
query. Since many search engines support a syntax that includes special
characters, boolean words, stopwords, and fields, search queries can become
complicated. In order to separate the wheat from the chafe, the supporting
words and symbols are removed and just the actual search terms (keywords)
are returned.

This class is used internally be Search::Tools::RegExp. You probably don't need
to use it directly. But if you do, read on.

=head1 METHODS

=head2 new( %opts )

The new() method instantiates a S::T::K object. With the exception
of extract(), all the following methods are can be passed as key/value
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

B<NOTE:> If a stopword is contained in a phrase, then the phrase 
will be split into its separate words based on whitespace.

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
