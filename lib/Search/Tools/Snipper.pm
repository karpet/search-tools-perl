package Search::Tools::Snipper;

#
# TODO GNU grep does this much better and faster.
# could we XS some of that beauty?
#

use strict;
use warnings;

use Carp;
use Search::Tools::XML;
use Search::Tools::RegExp;

use base qw( Search::Tools::Object );

our $VERSION = '0.23';
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
        snipper_name
        snipper_force
        snipper_type
        count
        collapse_whitespace
        ),
    @Search::Tools::Accessors
);

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->{snipper_type} ||= 'loop';
    $self->{occur}        ||= 5;
    $self->{max_chars}    ||= 300;
    $self->{context}      ||= 8;
    $self->{word_len}     ||= 5;
    $self->{show}         ||= 1;
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

    $self->_word_regexp;
    $self->_build_query;

    # default snipper is loop_snip since it is fastest for single words
    # but we can specify re_snip if we want
    if ( $self->snipper_type eq 're' ) {
        $self->snipper( \&_re_snip );
    }
    else {
        $self->snipper( \&_loop_snip ) unless $self->snipper;
    }

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

        push( @re, $q );

        my $r = {
            safe  => $q,
            plain => $self->rekw->re($_)->plain,
            html  => $self->rekw->re($_)->html
        };

        $self->{_re}->{$_} = $r;

    }
    my $j = join( '|', @re );
    $self->{_qre} = qr/($self->{_ignoreFirst}$j$self->{_ignoreLast})/i;

}

# I tried Text::Context but that was too slow
# here are several different models.
# I have found that loop_snip() is faster for single-word queries,
# while re_snip() seems to be the best compromise between speed and accuracy

sub snip {
    my $self = shift;
    my $text = shift or return '';
    my $func = $self->snipper;

    #carp "snipping: $text";

    # phrases must use re_snip()
    # so check if any of our queries contain a space
    if ( grep {/\ /} $self->rekw->keywords ) {
        $func = \&_re_snip unless $self->snipper_force;
    }

    # don't snip if we're less than the threshold
    return $text if length($text) < $self->max_chars;

    my $s = &$func( $self, $text );

    #carp "snipped: $s";

    # sanity check
    $s = $self->_dumb_snip($s) if ( length($s) > ( $self->max_chars * 2 ) );

    if ( $self->collapse_whitespace ) {
        $s =~ s,[\s\xa0]+,\ ,g;
    }

    return $s;

}

sub _loop_snip {

    my $self = shift;
    $self->snipper_name('loop_snip');

    my $txt = shift or return '';

    my $regexp = $self->{_qre};

    #carp "loop snip: $txt";

    #carp "regexp: $regexp";

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

        #print ">>\n" if $count % 2;
        #print "word: '$w'\n";

        $count++;
        next WORD if $count < $start_again;

        # the next WORD lets us skip past the last frag we excerpted

        my $last = $count - 1;
        my $next = $count + 1;

        #warn '-' x 30 . "\n";
        if ( $w =~ m/^$regexp$/ ) {

            #print "w: '$w' match: '$1'\n";

            my $before = $last - $context;
            $before = 0 if $before < 0;
            my $after = $next + $context;
            $after = $#words if $after > $#words;

            #warn "$before .. $last, $count, $next .. $after\n";

            my @before = @words[ $before .. $last ];
            my @after  = @words[ $next .. $after ];

            $total += grep {m/^$regexp$/i} ( @before, @after );
            $total++;    # for current $w

            my $t = join( '', @before, $w, @after );

            $t .= $ellip unless $count == $#words;

            #$t = $ellip . $t unless $count == 0;

            #warn "t: $t\n";

            #warn "total: $total\n";

            push( @snips, $t );
            last WORD if scalar @snips >= $occur;

            $start_again = $after;
        }

        last WORD if $total >= $occur;

    }

    #warn "snips: " . scalar @snips;
    #warn "words: $count\n";
    #warn "grandtotal: $total\n";
    #warn "occur: $occur\n";

    #warn '-' x 50 . "\n";

    $self->count( scalar(@snips) + $self->count );

    my $snippet = join( '', @snips );
    $snippet = $ellip . $snippet unless $snippet =~ m/^$words[0]/;

    $self->_escape($snippet);

    return $snippet;

}

sub _re_snip {

   # get first N matches for each q, then take one of each till we have $occur

    my $self = shift;
    my $text = shift;
    my @q    = $self->rekw->keywords;
    $self->snipper_name('re_snip');

    my $occur = $self->occur;
    my $Nchar = $self->context * $self->word_len;
    my $total = 0;
    my $notwc = $self->{_wc_regexp};

    # get minimum number of snips necessary to meet $occur
    my $snip_per_q = int( $occur / scalar(@q) ) + 1;

    my ( %snips, @snips, %ranges );

Q: for my $q (@q) {
        $snips{$q} = { t => [], offset => [] };

        # try simple regexp first, then more complex if we don't match
        next Q
            if $self->_re_match( \$text, $self->{_re}->{$q}->{plain},
            \$total, $snips{$q}, \%ranges, $Nchar, $snip_per_q );

        pos $text = 0;    # do we really need to reset this?

        $self->_re_match( \$text, $self->{_re}->{$q}->{html},
            \$total, $snips{$q}, \%ranges, $Nchar, $snip_per_q );

    }

    return $self->_dumb_snip($text) unless $total;

 # get all snips into one array in order they appeared in $text
 # should be a max of $snip_per_q in any one $q snip array
 # so we should have at least $occur in total, which we'll splice() if need be

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

    $snips[0] = $ellip . $snips[0] unless $text =~ m/^\Q$snips[0]/i;
    $snips[-1] .= $ellip unless $text =~ m/\Q$snips[-1]$/i;

    my $snip = join( $ellip, @snips );

    $self->count( scalar(@snips) + $self->count );

    $self->_escape($snip);

    return $snip;

}

sub _re_match {

# the .{0,$Nchar} regexp slows things WAY down. so just match, then use pos() to get
# chars before and after.

# if escape = 0 and if prefix or suffix contains a < or >, try to include entire tagset.

    my ( $self, $text, $re, $total, $snips, $ranges, $Nchar, $max_snips )
        = @_;

    my $t_len = length $$text;

    my $cnt = 0;

RE: while ( $$text =~ m/$re/gi ) {

        #		warn "re: '$re'\n";
        #		warn "\$1 = '$1' = ", ord( $1 ), "\n";
        #		warn "\$2 = '$2'\n";
        #		warn "\$3 = '$3' = ", ord( $3 ), "\n";

        my $match = $2;
        $cnt++;
        my $pos = pos $$text;

        #warn "already found $pos\n" if exists $ranges->{$pos};
        next RE if exists $ranges->{$pos};

        my $len = length $match;

        my $start_match = $pos - $len - 1;    # -1 to offset $1
        $start_match = 0 if $start_match < 0;

      # sanity
      #warn "match should be: '", substr( $$text, $start_match, $len ), "'\n";

        my $prefix_start
            = $start_match < $Nchar
            ? 0
            : $start_match - $Nchar;

        my $prefix_len = $start_match - $prefix_start;

        #$prefix_len++; $prefix_len++;

        my $suffix_start = $pos - 1;                      # -1 to offset $3
        my $suffix_len   = $Nchar;
        my $end          = $suffix_start + $suffix_len;

        # if $end extends beyond, that's ok, substr compensates

        $ranges->{$_}++ for ( $prefix_start .. $end );

        #		warn "prefix_start = $prefix_start\n";
        #		warn "prefix_len = $prefix_len\n";
        #		warn "start_match = $start_match\n";
        #		warn "len = $len\n";
        #		warn "pos = $pos\n";
        #		warn "char = $Nchar\n";
        #		warn "suffix_start = $suffix_start\n";
        #		warn "suffix_len = $suffix_len\n";
        #		warn "end = $end\n";

        my $prefix = substr( $$text, $prefix_start, $prefix_len );
        my $suffix = substr( $$text, $suffix_start, $suffix_len );

        #		warn "prefix: '$prefix'\n";
        #		warn "match:  '$match'\n";
        #		warn "suffix: '$suffix'\n";

        # try and get whole words if we split one up
        # _no_*_partial does this more rudely

# might be faster to do m/(\S)*$prefix/i
# but we couldn't guarantee position accuracy
# e.g. if $prefix matched more than once in $$text, we might pull the wrong \S*

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
    $self->snipper_name('dumb_snip');

    my $show = substr( $txt, 0, $max );
    $self->_no_end_partial($show);
    $show .= $ellip;
    $self->_escape($show);

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
    my $self = shift;
    if ( $self->escape ) {
        return Search::Tools::XML->escape( $_[0] );
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

=head2 snipper_name

The name of the internal snipper function used. In case you're curious.

=head2 snipper_force

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

