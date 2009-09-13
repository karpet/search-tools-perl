package Search::Tools::QueryParser;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Carp;
use Data::Dump qw( dump );
use Search::QueryParser;

# make sure we get correct ->utf8 encoding
use POSIX qw(locale_h);
use locale;
use Encode;
use Data::Dump;
use Search::Tools::Query;
use Search::Tools::UTF8;
use Search::Tools::RegExp;

our $VERSION = '0.24';

my $locale = setlocale(LC_CTYPE);
my ( $lang, $charset ) = split( m/\./, $locale );
$charset ||= q/iso-8859-1/;
$lang = q/en_US/ if $lang =~ m/^(posix|c)$/i;

my %Defaults = (
    locale                  => $locale,
    charset                 => $charset,
    lang                    => $lang,
    stopwords               => [],
    wildcard                => q/*/,
    word_re                 => qr/\w+(?:'\w+)*/,
    word_characters         => q/\w\'\-/,
    ignore_first_char       => q/\'\-/,
    ignore_last_char        => q/\'\-/,
    stemmer                 => undef,
    phrase_delim            => q/"/,
    ignore_case             => 1,
    and_word                => q/and|near\d*/,
    or_word                 => q/or/,
    not_word                => q/not/,
    ignore_fields           => {},
    treat_uris_like_phrases => 1,
);

__PACKAGE__->mk_accessors( keys %Defaults );

sub get_defaults {
    return {%Defaults};
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    for ( keys %Defaults ) {
        next if defined $self->{$_};
        $self->{$_} = $Defaults{$_};
    }

    # charset/locale/lang are a bit interdependent
    # so make sure charset/lang are set if locale is explicitly passed.
    if ( $self->{locale} ne $Defaults{locale} ) {
        ( $self->{lang}, $self->{charset} ) = split( m/\./, $self->{locale} );
        $self->{lang} = 'en_US' if $self->{lang} =~ m/^(posix|c)$/i;
        $self->{charset} ||= $Defaults{charset};
    }

    # make sure ignore_fields is a hash ref
    if ( ref( $self->{ignore_fields} ) eq 'ARRAY' ) {
        $self->{ignore_fields}
            = { map { $_ => $_ } @{ $self->{ignore_fields} } };
    }

    return $self;
}

sub parse {
    my $self = shift;
    my $query_str = shift or croak "query required";
    if ( ref $query_str ) {
        croak "query must be a scalar string";
    }
    my $kw = $self->_extract_keywords($query_str);
    my $regex = Search::Tools::RegExp->new( kw => $self )->build($kw);
    return Search::Tools::Query->new(
        parser   => $kw->{parser},
        keywords => $kw->{keywords},
        str      => $query_str,
        regex    => $regex,
    );
}

sub _extract_keywords {
    my $self      = shift;
    my $query     = shift or croak "need query to extract keywords";
    my $stopwords = $self->stopwords;
    my $and_word  = $self->and_word;
    my $or_word   = $self->or_word;
    my $not_word  = $self->not_word;
    my $wildcard  = $self->wildcard;
    my $phrase    = $self->phrase_delim;
    my $igf       = $self->ignore_first_char;
    my $igl       = $self->ignore_last_char;
    my $wordchar  = $self->word_characters;

    my $esc_wildcard = quotemeta($wildcard);
    my $word_re      = qr/([$wordchar]+($esc_wildcard)?)/;

    # backcompat allows for query to be array ref.
    # this called only from S::T::Keywords
    my @query = @{ ref $query ? $query : [$query] };

    $stopwords = [ split( /\s+/, $stopwords ) ] unless ref $stopwords;
    my %stophash = map { to_utf8( lc($_), $self->charset ) => 1 } @$stopwords;
    my ( %words, %uniq, $c );
    my $parser = Search::QueryParser->new(
        rxAnd => qr{$and_word}i,
        rxOr  => qr{$or_word}i,
        rxNot => qr{$not_word}i,
    );

Q: for my $q (@query) {
        $q = lc($q) if $self->ignore_case;
        $q = to_utf8( $q, $self->charset );
        my $tree = $parser->parse( $q, 1 ) or croak $parser->err;
        $self->debug && carp "parsetree: " . Data::Dump::dump($tree);
        $self->_get_value_from_tree( \%uniq, $tree, $c );
    }

    $self->debug && carp "parsed: " . Data::Dump::dump( \%uniq );

    my $count = scalar( keys %uniq );

    # parse uniq into word tokens
    # including removing stop words

    $self->debug && carp "word_re: $word_re";

U: for my $u ( sort { $uniq{$a} <=> $uniq{$b} } keys %uniq ) {

        my $n = $uniq{$u};

        # only phrases have space
        # but due to our word_re, a single non-spaced string
        # might actually be multiple word tokens
        my $isphrase = $u =~ m/\s/ || 0;

        if ( $self->treat_uris_like_phrases ) {

            # special case: treat email addresses, uris, as phrase
            $isphrase ||= $u =~ m/[$wordchar][\@\.\\][$wordchar]/ || 0;
        }

        $self->debug && carp "$u -> isphrase = $isphrase";

        my @w = ();

    TOK: for my $w ( split( m/\s+/, to_utf8( $u, $self->charset ) ) ) {

            next TOK unless $w =~ m/\S/;

            $w =~ s/\Q$phrase\E//g;

            while ( $w =~ m/$word_re/g ) {
                my $tok = _untaint($1);

                # strip ignorable chars
                $tok =~ s/^[$igf]+//;
                $tok =~ s/[$igl]+$//;

                unless ($tok) {
                    $self->debug && carp "no token for '$w' $word_re";
                    next TOK;
                }

                $self->debug && carp "found token: $tok";

                if ( exists $stophash{ lc($tok) } ) {
                    $self->debug && carp "$tok = stopword";
                    next TOK unless $isphrase;
                }

                unless ($isphrase) {
                    next TOK if $tok =~ m/^($and_word|$or_word|$not_word)$/i;
                }

                # if tainting was on, odd things can happen.
                # so check one more time
                $tok = to_utf8( $tok, $self->charset );

                # final sanity check
                if ( !Encode::is_utf8($tok) ) {
                    carp "$tok is NOT utf8";
                    next TOK;
                }

                #$self->debug && carp "pushing $tok into wordlist";
                push( @w, $tok );

            }

        }

        next U unless @w;

        #$self->debug && carp "joining \@w: " . Data::Dump::dump(\@w);
        if ($isphrase) {
            $words{ join( ' ', @w ) } = $n + $count++;
        }
        else {
            for (@w) {
                $words{$_} = $n + $count++;
            }
        }

    }

    $self->debug && carp "tokenized: " . Data::Dump::dump( \%words );

    # make sure we don't have 'foo' and 'foo*'
    for ( keys %words ) {
        if ( $_ =~ m/$esc_wildcard/ ) {
            ( my $copy = $_ ) =~ s,$esc_wildcard,,g;

            # delete the more exact of the two
            # since the * will match both
            delete( $words{$copy} );
        }
    }

    $self->debug && carp "wildcards removed: " . Data::Dump::dump( \%words );

    # if any words need to be stemmed
    if ( $self->stemmer ) {

        # split each $word into words
        # stem each word
        # if stem ne word, break into chars and find first N common
        # rejoin $uniq

        #carp "stemming ON\n";

    K: for ( keys %words ) {
            my (@w) = split /\s+/;
        W: for my $w (@w) {
                my $func = $self->stemmer;
                my $f = &$func( $self, $w );

                #warn "w: $w\nf: $f\n";

                if ( $f ne $w ) {

                    my @stemmed = split //, $f;
                    my @char    = split //, $w;
                    $f = '';    #reset
                    while ( @char && @stemmed && $stemmed[0] eq $char[0] ) {
                        $f .= shift @stemmed;
                        shift @char;
                    }

                }

                # add wildcard to indicate chars were lost
                $w = $f . $wildcard;
            }
            my $new = join ' ', @w;
            if ( $new ne $_ ) {
                $words{$new} = $words{$_};
                delete $words{$_};
            }
        }

    }

    $self->debug && carp "stemming done: " . Data::Dump::dump( \%words );

    # sort keeps query in same order as we entered
    return {
        keywords => [ sort { $words{$a} <=> $words{$b} } keys %words ],
        parser   => $parser
    };

}

# stolen nearly verbatim from Taint::Runtime
# it's unclear to me why our regexp results in tainted vars.
# if we untaint $query in initial extract() set up,
# subsequent matches against word_re still end up tainted.
# might be a Unicode weirdness?
sub _untaint {
    my $str = shift;
    my $ref = ref($str) ? $str : \$str;
    if ( !defined $$ref ) {
        $$ref = undef;
    }
    else {
        $$ref
            = ( $$ref =~ /(.*)/ )
            ? $1
            : do { confess("Couldn't find data to untaint") };
    }
    return ref($str) ? 1 : $str;
}

sub _get_value_from_tree {
    my $self      = shift;
    my $uniq      = shift;
    my $parseTree = shift;
    my $c         = shift;

    # we only want the values from non minus queries
    for my $node ( grep { $_ eq '+' || $_ eq '' } keys %$parseTree ) {
        my @branches = @{ $parseTree->{$node} };

        for my $leaf (@branches) {
            my $v = $leaf->{value};
            next if exists $self->ignore_fields->{ $leaf->{field} };

            if ( ref $v ) {
                $self->_get_value_from_tree( $uniq, $v, $c );
            }
            else {

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

Search::Tools::QueryParser - convert string queries into objects

=head1 SYNOPSIS

 use Search::Tools::QueryParser;
 my $qparser = Search::Tools::QueryParser->new(
        
        # regex to define a "word"
            word_re        => qr/\w+(?:'\w+)*/,
        
        # or assemble a definition from the following
            word_characters     => q/\w\'\-/,
            ignore_first_char   => q/\+\-/,
            ignore_last_char    => q/\+\-/,
            
        # words to ignore
            stopwords           => [qw( the )],
            
        # query operators
            and_word            => q(and),
            or_word             => q(or),
            not_word            => q(not),
            phrase_delim        => q("),
            treat_uris_like_phrases => 1,
            ignore_fields       => [qw( site )],
            wildcard            => quotemeta(q(*)),
                        
        # language-specific settings
            stemmer             => &your_stemmer_here,       
            charset             => 'iso-8859-1',
            lang                => 'en_US',
            locale              => 'en_US.iso-8859-1',

        # development help
            debug               => 0,
    );
    
 my $query    = $qparser->parse(q(the quick color:brown "fox jumped"));
 my $keywords = $query->keywords; # ['quick', 'brown', '"fox jumped"']
 my $regexp   = $query->regexp_for($keywords->[0]); # S::T::R::Keyword
 my $tree     = $query->tree; # the Search::QueryParser-parsed struct
 print "$query\n";  # the quick color:brown "fox jumped"
 print $query->str . "\n"; # same thing
 
 
=head1 DESCRIPTION

Search::Tools::QueryParser turns search queries into objects that can
be applied for highlighting, spelling, and extracting matching snippets
from source documents.

This is a new class in Search::Tools version 0.24. It supercedes
the Search::Tools::RegExp and Search::Tools::Keywords public API, but
backwords compatability is preserved except where noted.

=head1 METHODS

=head2 new( %opts )

The new() method instantiates a S::T::K object. With the exception
of extract(), all the following methods can be passed as key/value
pairs in new().
 
=head2 parse( I<query> )

The parse() method parses I<query> and returns a Search::Tools::Query object.

I<query> must be a scalar string.

B<NOTE:> All queries are converted to UTF-8. See the C<charset> param.

=head2 stemmer

The stemmer function is used to find the root 'stem' of a word. There are many
stemming algorithms available, including many on CPAN. The stemmer function
should expect to receive two parameters: the Keywords object and the word to be
stemmed. It should return exactly one value: the stemmed word.

Example stemmer function:

 use Lingua::Stem;
 my $stemmer = Lingua::Stem->new;
 
 sub mystemfunc {
     my ($parser, $word) = @_;
     return $stemmer->stem($word)->[0];
 }
 
 # and pass to the new() method:
 
 my $qparser = Search::Tools::QueryParser->new(stemmer => \&mystemfunc);
     
=head2 stopwords

A list of common words that should be ignored in parsing out keywords. 
May be either a string that will be split on whitespace, or an array ref.

B<NOTE:> If a stopword is contained in a phrase, then the phrase 
will be tokenized into words based on whitespace, then the stopwords removed.

=head2 ignore_first_char

String of characters to strip from the beginning of all words.

=head2 ignore_last_char

String of characters to strip from the end of all words.

=head2 ignore_case

All queries are run through Perl's built-in lc() function before
parsing. The default is C<1> (true). Set to C<0> (false) to preserve
case.

=head2 ignore_fields

Value may be a hash or array ref of field names to ignore in query parsing.
Example:

 ignore_fields => [qw( site )]

would parse the query:

 site:foo.bar AND baz   # keywords = baz

=head2 treat_uris_like_phrases

Boolean (default true (1)).

If set to true, queries like B<foo@bar.com> will be treated like a single
phrase B<"foo bar com"> instead of being split into three separate keywords.

=head2 and_word

Default: C<and|near\d*>

=head2 or_word

Default: C<or>

=head2 not_word

Default: C<not>

=head2 wildcard

Default: C<*>

=head2 locale

Set a locale explicitly for a Keywords object.If not set, 
the locale is inherited from the C<LC_CTYPE> environment
variable.

=head2 lang

Base language. If not set, extracted from C<locale> or defaults to C<en_US>.

=head2 charset

Base charset used for converting queries to UTF-8. If not set, 
extracted from C<locale> or defaults to C<iso-8859-1>.

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

Search::QueryParser

=cut

