package Search::Tools::Snipper;
use strict;
use warnings;

use Carp;
use Data::Dump qw( dump );
use Search::Tools::XML;
use Search::Tools::RegExp;
use Search::Tools::UTF8;
use Search::Tools::Tokenizer;
use Search::Tools::HeatMap;

use base qw( Search::Tools::Object );

our $VERSION = '0.24';
our $ellip   = ' ... ';

__PACKAGE__->mk_accessors(
    qw(
        query
        rekw
        occur
        context
        max_chars
        word_len
        show
        escape
        snipper
        type_used
        force
        type
        count
        collapse_whitespace
        tokenizer
        ),
    @Search::Tools::Accessors
);

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->{type}      ||= 'token';
    $self->{occur}     ||= 5;
    $self->{max_chars} ||= 300;
    $self->{context}   ||= 8;
    $self->{word_len}  ||= 4;
    $self->{show}      ||= 1;
    for (qw/collapse_whitespace/) {
        $self->{$_} = 1 unless defined $self->{$_};
    }

    if ( !$self->query ) {
        croak "query required.";
    }
    elsif ( ref $self->query eq 'ARRAY' or !ref $self->query ) {
        my $re = Search::Tools::RegExp->new;
        $self->rekw( $re->build( $self->query ) );
    }
    elsif ( $self->query->isa('Search::Tools::RegExp::Keywords') ) {
        $self->rekw( $self->query );
    }
    else {
        croak
            "query must be either a string or Search::Tools::RegExp::Keywords object";
    }

    unless ( $self->rekw ) {
        croak "Search:Tools::RegExp::Keywords object required";
    }

    #
    $self->{tokenizer} = Search::Tools::Tokenizer->new();  # TODO construct re
    $self->_word_regexp;
    $self->_build_query;

    $self->count(0);

}

sub _word_regexp {

    # this based on SWISH::PhraseHighlight::set_match_regexp()

    my $self = shift;
    my $wc   = $self->rekw->word_characters;
    $self->{_wc_regexp}
        = qr/[^$wc]+/io;    # regexp for splitting into swish-words

    my $igf = $self->rekw->ignore_first_char;
    my $igl = $self->rekw->ignore_last_char;
    for ( $igf, $igl ) {
        if ($_) {
            $_ = "[$_]*";
        }
        else {
            $_ = '';
        }
    }

    $self->{_ignoreFirst} = $igf;
    $self->{_ignoreLast}  = $igl;

}

sub _build_query {
    my $self     = shift;
    my $wildcard = $self->rekw->wildcard || '*';
    my $wild_esc = quotemeta($wildcard);

    # create regexp for loop_snip()
    # other regexp come from S::H::RegExp
    my @re;
    my $wc = $self->rekw->word_characters;

    for ( $self->rekw->keywords ) {

        my $q = quotemeta($_);    # quotemeta speeds up the match, too
                                  # even though we have to unquote below

        $q =~ s/\\$wild_esc/[$wc]*/;    # wildcard match is very approximate

        # treat phrases like OR'd words
        # since that will just create more matches.
        # if hiliting later, the phrase will be treated as such.
        $q =~ s/(\\ )+/\|/g;

        push( @re, $q );

        my $r = {
            safe  => $q,
            plain => $self->rekw->re($_)->plain,
            html  => $self->rekw->re($_)->html
        };

        $self->{_re}->{$_} = $r;

    }
    my $j = sprintf( '(%s)', join( '|', @re ) );
    $self->{_qre} = qr/$j/i;

}

# I tried Text::Context but that was too slow
# here are several different models.
# I have found that loop_snip() is faster for single-word queries,
# while re_snip() seems to be the best compromise between speed and accuracy

sub _pick_snipper {
    my ( $self, $text ) = @_;

    # default snipper is loop_snip since it is fastest for single words
    # but we can specify re_snip if we want
    my $func = \&_token_snip;

    #    if (!$self->force
    #        && ($self->type eq 're'
    #
    #            # phrases must use regexp
    #            # so check if any of our queries contain a space
    #            || grep {/\ /} $self->rekw->keywords
    #
    #            # or if text looks like HTML/XML
    #            || Search::Tools::RegExp->isHTML($text)
    #        )
    #        )
    #    {
    #        $func = \&_re_snip;
    #    }

    return $func;
}

sub _normalize_whitespace {
    $_[0] =~ s,[\s\xa0]+,\ ,go;
}

sub snip {
    my $self = shift;
    my $text = shift or return '';

    # normalize encoding, esp for regular expressions.
    $text = to_utf8($text);

    # don't snip if we're less than the threshold
    return $text if length($text) < $self->max_chars;

    if ( $self->collapse_whitespace ) {
        _normalize_whitespace($text);
    }

    # we calculate the snipper each time since caller
    # may set type() or snipper() between calls to snip().
    my $func = $self->snipper || $self->_pick_snipper($text);

    my $s = &$func( $self, $text );

    $self->debug and warn "snipped: '$s'\n";

    # sanity check
    if ( length($s) > ( $self->max_chars * 4 ) ) {
        $s = $self->_dumb_snip($s);
        $self->debug and warn "too long. dumb snip: '$s'\n";
    }
    elsif ( !length($s) ) {
        $s = $self->_dumb_snip($text);
        $self->debug and warn "too short. dumb snip: '$s'\n";
    }

    # escape entities before collapsing whitespace.
    $s = $self->_escape($s);

    if ( $self->collapse_whitespace ) {
        _normalize_whitespace($s);
    }

    return $s;

}

sub _token_snip {
    my $self = shift;
    my $qre  = $self->{_qre};
    
    $self->debug and warn "$qre";

    # we don't bother testing for phrases here.
    # instead we rely on HeatMap to find them for us later.
    my $tokens = $self->tokenizer->tokenize(
        $_[0],
        sub {
            if ( $_[0] =~ /^$qre$/ ) {

                #warn "---------- HOT MATCH $_[0] [$qre] --------";
                $_[0]->set_hot(1);
            }
        }
    );

    my $heatmap = Search::Tools::HeatMap->new(
        tokens      => $tokens,
        window_size => $self->{context},
    );

    $self->debug and dump $heatmap;

    my $tokens_arr = $tokens->as_array;

    #warn "snips: " . dump \@snips;
    if ( $heatmap->has_spans ) {

        # stringify positions
        my @snips;
        for my $span ( @{ $heatmap->spans } ) {

            $self->debug and warn '>>>' . $span->{str_w_pos} . '<<<';
            push( @snips, $span->{str} );
        }
        my $occur_index = $self->occur - 1;
        if ( $#snips > $occur_index ) {
            @snips = @snips[ 0 .. $occur_index ];
        }
        my $snip = join( ' ... ', @snips );
        my $snips_start_with_query = $_[0] =~ m/^\Q$snip\E/;
        my $snips_end_with_query   = $_[0] =~ m/\Q$snip\E$/;
        my $extract                = join( '',
            ( $snips_start_with_query ? '' : ' ... ' ),
            $snip, ( $snips_end_with_query ? '' : ' ... ' ) );
        return $extract;
    }
    else {
        return $self->_dumb_snip( $_[0] );
    }

}

sub _loop_snip {

    my $self = shift;
    $self->type_used('loop');

    my $txt = shift or return '';

    my $regexp = $self->{_qre};

    #carp "loop snip: $txt";

    $self->debug and carp "loop snip regexp: $regexp";

    my $debug = $self->debug || 0;

    # no matches
    return $self->_dumb_snip($txt) unless $txt =~ m/$regexp/;

    #carp "loop snip: $txt";

    my $context = $self->context;
    my $occur   = $self->occur;
    my @snips;

    my $notwc = $self->{_wc_regexp};

    my @words       = split( /($notwc)/, $txt );
    my $count       = -1;
    my $start_again = $count;
    my $total       = 0;

WORD: for my $w (@words) {

        if ( $debug > 1 ) {
            warn ">>\n" if $count % 2;
            warn "word: '$w'\n";
        }

        $count++;
        next WORD if $count < $start_again;

        # the next WORD lets us skip past the last frag we excerpted

        my $last = $count - 1;
        my $next = $count + 1;

        #warn '-' x 30 . "\n";
        if ( $w =~ m/^$regexp$/ ) {

            if ( $debug > 1 ) {
                warn "w: '$w' match: '$1'\n";
            }

            my $before = $last - $context;
            $before = 0 if $before < 0;
            my $after = $next + $context;
            $after = $#words if $after > $#words;

            if ( $debug > 1 ) {
                warn "$before .. $last, $count, $next .. $after\n";
            }

            my @before = @words[ $before .. $last ];
            my @after  = @words[ $next .. $after ];

            $total += grep {m/^$regexp$/i} ( @before, @after );
            $total++;    # for current $w

            my $t = join( '', @before, $w, @after );

            $t .= $ellip unless $count == $#words;

            #$t = $ellip . $t unless $count == 0;

            if ( $debug > 1 ) {
                warn "t: $t\n";
                warn "total: $total\n";
            }

            push( @snips, $t );
            last WORD if scalar @snips >= $occur;

            $start_again = $after;
        }

        last WORD if $total >= $occur;

    }

    if ( $debug > 1 ) {
        carp "snips: " . scalar @snips;
        carp "words: $count\n";
        carp "grandtotal: $total\n";
        carp "occur: $occur\n";
        carp '-' x 50 . "\n";

    }

    $self->count( scalar(@snips) + $self->count );
    my $snippet = join( '', @snips );
    $self->debug and warn "before no_start_partial: '$snippet'\n";
    _no_start_partial($snippet);
    $snippet = $ellip . $snippet unless $snippet =~ m/^$words[0]/;

    return $snippet;
}

sub _re_snip {

   # get first N matches for each q, then take one of each till we have $occur

    my $self = shift;
    my $text = shift;
    my @q    = $self->rekw->keywords;
    $self->type_used('re');

    my $occur = $self->occur;
    my $Nchar = $self->context * $self->word_len;
    my $total = 0;
    my $notwc = $self->{_wc_regexp};

    # get minimum number of snips necessary to meet $occur
    my $snip_per_q = int( $occur / scalar(@q) );
    $snip_per_q ||= 1;

    my ( %snips, @snips, %ranges, $snip_starts_with_query );
    $snip_starts_with_query = 0;

Q: for my $q (@q) {
        $snips{$q} = { t => [], offset => [] };

        $self->debug and warn "$q : $snip_starts_with_query";

        # try simple regexp first, then more complex if we don't match
        next Q
            if $self->_re_match( \$text, $self->{_re}->{$q}->{plain},
            \$total, $snips{$q}, \%ranges, $Nchar, $snip_per_q,
            \$snip_starts_with_query );

        $self->debug and warn "failed match on plain regexp";

        pos $text = 0;    # do we really need to reset this?

        unless (
            $self->_re_match(
                \$text,      $self->{_re}->{$q}->{html},
                \$total,     $snips{$q},
                \%ranges,    $Nchar,
                $snip_per_q, \$snip_starts_with_query
            )
            )
        {
            $self->debug and warn "failed match on html regexp";
        }

    }

    return $self->_dumb_snip($text) unless $total;

    # get all snips into one array in order they appeared in $text
    # should be a max of $snip_per_q in any one $q snip array
    # so we should have at least $occur in total,
    # which we'll splice() if need be.

    my %offsets;
    for my $q ( keys %snips ) {
        my @s = @{ $snips{$q}->{t} };
        my @o = @{ $snips{$q}->{offset} };

        my $i = 0;
        for (@s) {
            $offsets{$_} = $o[$i];
        }
    }
    @snips = sort { $offsets{$a} <=> $offsets{$b} } keys %offsets;

    # max = $occur
    @snips = splice @snips, 0, $occur;

    $self->debug and warn dump( \@snips );

    my $snip = join( $ellip, @snips );
    _no_start_partial($snip) unless $snip_starts_with_query;
    $snip = $ellip . $snip unless $text =~ m/^\Q$snips[0]/i;
    $snip .= $ellip unless $text =~ m/\Q$snips[-1]$/i;

    $self->count( scalar(@snips) + $self->count );

    return $snip;

}

sub _re_match {

    # the .{0,$Nchar} regexp slows things WAY down. so just match,
    # then use pos() to get chars before and after.

    # if escape = 0 and if prefix or suffix contains a < or >,
    # try to include entire tagset.

    my ( $self, $text, $re, $total, $snips, $ranges, $Nchar, $max_snips,
        $snip_starts_with_query )
        = @_;

    my $t_len = length $$text;

    my $cnt = 0;

    if ( $self->debug ) {
        warn "re_match regexp: >$re<\n";
        warn "max_snips: $max_snips\n";
    }

RE: while ( $$text =~ m/$re/g ) {

        my $pos          = pos $$text;
        my $before_match = $1;
        my $match        = $2;
        my $after_match  = $3;
        $cnt++;
        my $len  = length $match;
        my $blen = length $before_match;
        if ( $self->debug ) {
            warn "re: '$re'\n";
            warn "\$1 = '$before_match' = ", ord($before_match), "\n";
            warn "\$2 = '$match'\n";
            warn "\$3 = '$after_match' = ", ord($after_match), "\n";
            warn "pos = $pos\n";
            warn "len = $len\n";
            warn "blen= $blen\n";
        }

        if ( $self->debug && exists $ranges->{$pos} ) {
            warn "already found $pos\n";
        }

        next RE if exists $ranges->{$pos};

        my $start_match = $pos - $len - ( $blen || 1 );
        $start_match = 0 if $start_match < 0;

        $$snip_starts_with_query = 1 if $start_match == 0;

        # sanity
        $self->debug
            and warn "match should be [$start_match $len]: '",
            substr( $$text, $start_match, $len ), "'\n";

        my $prefix_start
            = $start_match < $Nchar
            ? 0
            : $start_match - $Nchar;

        my $prefix_len = $start_match - $prefix_start;

        #$prefix_len++; $prefix_len++;

        my $suffix_start = $pos - length($after_match);
        my $suffix_len   = $Nchar;
        my $end          = $suffix_start + $suffix_len;

        # if $end extends beyond, that's ok, substr compensates

        $ranges->{$_}++ for ( $prefix_start .. $end );
        my $prefix = substr( $$text, $prefix_start, $prefix_len );
        my $suffix = substr( $$text, $suffix_start, $suffix_len );

        if ( $self->debug ) {
            warn "prefix_start = $prefix_start\n";
            warn "prefix_len = $prefix_len\n";
            warn "start_match = $start_match\n";
            warn "len = $len\n";
            warn "pos = $pos\n";
            warn "char = $Nchar\n";
            warn "suffix_start = $suffix_start\n";
            warn "suffix_len = $suffix_len\n";
            warn "end = $end\n";
            warn "prefix: '$prefix'\n";
            warn "match:  '$match'\n";
            warn "suffix: '$suffix'\n";
        }

        # try and get whole words if we split one up
        # _no_*_partial does this more rudely

        # might be faster to do m/(\S)*$prefix/i
        # but we couldn't guarantee position accuracy
        # e.g. if $prefix matched more than once in $$text,
        # we might pull the wrong \S*

        unless ( $prefix =~ m/^\s/
            or substr( $$text, $prefix_start - 1, 1 ) =~ m/(\s)/ )
        {
            while ( --$prefix_start >= 0
                and substr( $$text, $prefix_start, 1 ) =~ m/(\S)/ )
            {
                my $onemorechar = $1;

                #warn "adding $onemorechar to prefix\n";
                $prefix = $onemorechar . $prefix;

                #last if $prefix_start <= 0 or $onemorechar !~ /\S/;
            }
        }

        # do same for suffix

        # We get error here under -w
        # about substr outside of string -- is $end undefined sometimes??

        unless ( $suffix =~ m/\s$/ or substr( $$text, $end, 1 ) =~ m/(\s)/ ) {
            while ( $end <= $t_len
                and substr( $$text, $end++, 1 ) =~ m/(\S)/ )
            {

                my $onemore = $1;

                #warn "adding $onemore to suffix\n";
                #warn "before '$suffix'\n";
                $suffix .= $onemore;

                #warn "after  '$suffix'\n";
            }
        }

        # will likely fail to include one half of tagset if other is complete
        unless ( $self->escape ) {
            my $sanity = 0;
            my @l      = ( $prefix =~ /(<)/g );
            my @r      = ( $prefix =~ /(>)/g );
            while ( scalar @l != scalar @r ) {

                @l = ( $prefix =~ /(<)/g );
                @r = ( $prefix =~ /(>)/g );
                last
                    if scalar @l
                        == scalar @r;    # don't take any more than we need to

                my $onemorechar = substr( $$text, $prefix_start--, 1 );

                #warn "tagfix: adding $onemorechar to prefix\n";
                $prefix = $onemorechar . $prefix;
                last if $prefix_start <= 0;
                last if $sanity++ > 100;

            }

            $sanity = 0;
            while ( $suffix =~ /<(\w+)/ && $suffix !~ /<\/$1>/ ) {

                my $onemorechar = substr( $$text, $end, 1 );

                #warn "tagfix: adding $onemorechar to suffix\n";
                $suffix .= $onemorechar;
                last if ++$end > $t_len;
                last if $sanity++ > 100;

            }
        }

        #		warn "prefix: '$prefix'\n";
        #		warn "match:  '$match'\n";
        #		warn "suffix: '$suffix'\n";

        my $context = join( '', $prefix, $match, $suffix );

        #warn "context is '$context'\n";

        push( @{ $snips->{t} },      $context );
        push( @{ $snips->{offset} }, $prefix_start );

        $$total++;

        #		warn '-' x 40, "\n";

        last if $cnt >= $max_snips;
    }

    return $cnt;
}

sub _dumb_snip {

    # just grap the first X chars and return

    my $self = shift;
    return '' unless $self->show;

    my $txt = shift;
    my $max = $self->max_chars;
    $self->type_used('dumb');

    my $show = substr( $txt, 0, $max );
    _no_end_partial($show);
    $show .= $ellip;

    $self->count( 1 + $self->count );

    return $show;

}

sub _no_start_partial {
    $_[0] =~ s/^\S+\s+//gs;
}

sub _no_end_partial {
    $_[0] =~ s/\s+\S+$//gs;
}

sub _escape {
    if ( $_[0]->escape ) {
        return Search::Tools::XML->escape( $_[1] );
    }
    else {
        return $_[1];
    }
}

1;
__END__

=pod

=head1 NAME

Search::Tools::Snipper - extract keywords in context

=head1 SYNOPSIS

 my $query = [ qw/ quick dog / ];
 my $text  = 'the quick brown fox jumped over the lazy dog';
 
 my $s = Search::Tools::Snipper->new(
            occur       => 3,
            context     => 8,
            word_len    => 5,
            max_chars   => 300,
            query       => $query
            );
            
 print $s->snip( $text );
 
 
=head1 DESCRIPTION

Search::Tools::Snipper extracts keywords and their context from a larger
block of text. The larger block may be plain text or HTML/XML.


=head1 METHODS

=head2 new( query => I<query> )

Instantiate a new object. I<query> must be either a scalar string, an array of strings,
or a Search::Tools::RegExp::Keywords object.

Many of the following methods
are also available as key/value pairs to new().

=head2 occur

The number of snippets that should be returned by snip().

Available via new().

=head2 context

The number of context words to include in the snippet.

Available via new().

=head2 max_chars

The maximum number of characters (not bytes! under Perl >= 5.8) to return
in a snippet. B<NOTE:> This is only used to test whether I<test> is worth
snipping at all, or if no keywords are found (see show()).

Available via new().

=head2 word_len

The estimated average word length used in combination with context(). You can
usually ignore this value.

Available via new().

=head2 show

Boolean flag indicating whether snip() should succeed no matter what, or if it should
give up if no snippets were found. Default is 1 (true).

If no matches are found, the first I<max_chars> of the snippet are returned.

Available via new().

=head2 escape

Boolean flag indicating whether snip() should escape any HTML/XML markup in the resulting
snippet or not. Default is 0 (false).

Available via new().

=head2 snipper

The CODE ref used by the snip() method for actually extracting snippets. You can
use your own snipper function if you want (though if you have a better snipper algorithm
than the ones in this module, why not share it?). If you go this route, have a look
at the source code for snip() to see how snipper() is used.

Available via new().

=head2 type

There are three different algorithms used internally for snipping text.
They are:

=over

=item loop

Fastest for single-word queries.

=item re (default)

The regular expression algorithm. Slower than I<loop> for the common
case (single word) but the best compromise between
speed and accuracy.

=item dumb

Just grabs the first B<max_chars> characters and returns it,
doing a little clean up to prevent partial words from ending the snippet
and (optionally) escaping the text.

=back

=cut

=head2 type_used

The name of the internal snipper function used. In case you're curious.

=head2 force

Boolean flag indicating whether the snipper() value should always be used,
regardless of the type of query keyword. Default is 0 (false).

Available via new().

=head2 count

The number of snips made by the Snipper object.

=head2 collapse_whitespace

Boolean flag indicating whether multiple whitespace characters
should be collapsed into a single space. A whitespace character
is defined as anything that Perl's C<\s> pattern matches, plus
the nobreak space (C<\xa0>). Default is 1 (true).

Available via new().

=head2 snip( I<text> )

Return a snippet of text from I<text> that matches
I<query> plus context() words of context. Matches are case insensitive.

The snippet returned will be in UTF-8 encoding, regardless of the encoding
of I<text>.

=head2 rekw

Returns the internal Search::Tools::RegExp::Keywords object.

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

SWISH::HiLiter

=cut

