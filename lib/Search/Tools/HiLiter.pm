package Search::Tools::HiLiter;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Carp;
use Search::Tools::XML;
use Search::Tools::UTF8;

our $VERSION = '0.44';

my $XML = Search::Tools::XML->new;

__PACKAGE__->mk_accessors(
    qw(
        query
        tag
        class
        style
        text_color
        colors
        tty
        ttycolors
        no_html
        )
);

sub init {
    my $self = shift;
    my %args = $self->_normalize_args(@_);
    $self->SUPER::init(%args);

    if ( $self->debug ) {
        carp "debug level set at " . $self->debug;
    }

    $self->{tag} ||= 'span';
    $self->{colors} ||= [ '#ffff99', '#99ffff', '#ffccff', '#ccccff' ];
    $self->{ttycolors} ||= [ 'bold blue', 'bold red', 'bold green' ];

    if ( $self->tty ) {
        eval { require Term::ANSIColor };
        $self->tty(0) if $@;
    }

    $self->_build_tags;
}

sub terms {
    return shift->{query}->terms;
}

sub keywords {
    return @{ shift->terms };
}

sub _phrases {
    my $self = shift;
    my $q    = $self->{query};
    return grep { $q->regex_for($_)->is_phrase } @{ $q->terms };
}

sub _singles {
    my $self = shift;
    my $q    = $self->{query};
    return grep { !$q->regex_for($_)->is_phrase } @{ $q->terms };
}

sub _kworder {
    my $self = shift;

    # do phrases first so that duplicates privilege phrases

    return ( $self->_phrases, $self->_singles );
}

sub _build_tags {
    my $self = shift;

    my $t         = {};
    my @colors    = @{ $self->colors };
    my @ttycolors = @{ $self->ttycolors };
    my $tag       = $self->tag;

    my $n = 0;
    my $m = 0;

    for my $q ( $self->_kworder ) {

        # if tty flag is on, use ansicolor instead of html
        # if debug flag is on, use both html and ansicolor

        my ( %tags, $opener );
        $tags{open}  = '';
        $tags{close} = '';
        if ( $self->class ) {
            $opener = qq/<$tag class="/ . $self->class . qq/">/;
        }
        elsif ( $self->style ) {
            $opener = qq/<$tag style="/ . $self->style . qq/">/;
        }
        elsif ( $self->text_color ) {
            $opener
                = qq/<$tag style="color:/
                . $self->text_color
                . qq/;background:/
                . $colors[$n] . qq/">/;
        }
        else {
            $opener = qq/<$tag style="background:/ . $colors[$n] . qq/">/;
        }

        if ( $self->tty ) {
            $tags{open} .= $opener if $self->debug && !$self->no_html;
            $tags{open}  .= Term::ANSIColor::color( $ttycolors[$m] );
            $tags{close} .= Term::ANSIColor::color('reset');
            $tags{close} .= "</$tag>" if $self->debug && !$self->no_html;
        }
        else {
            $tags{open}  .= $opener;
            $tags{close} .= "</$tag>";
        }

        $t->{$q} = \%tags;

        $n = 0 if ++$n > $#colors;
        $m = 0 if ++$m > $#ttycolors;
    }

    $self->{_tags} = $t;
}

sub open_tag {
    my $self = shift;
    my $q = shift or croak "need query to get open_tag";
    return $self->{_tags}->{$q}->{open} || '';
}

sub close_tag {
    my $self = shift;
    my $q = shift or croak "need query to get close_tag";
    return $self->{_tags}->{$q}->{close} || '';
}

sub light {
    my $self = shift;
    my $text = shift or return '';

    # force upgrade. this is so regex will match ok.
    $text = to_utf8($text);

    if ( $XML->looks_like_html($text) && !$self->no_html ) {

        #warn "running ->html";
        return $self->html($text);
    }
    else {

        #warn "running ->plain";
        return $self->plain($text);
    }
}

*hilite = \&light;

sub _get_real_html {
    my $self  = shift;
    my $text  = shift;
    my $re    = shift;
    my $m     = {};
    my $debug = $self->debug > 1 ? 1 : 0;

    # $1 should be st_bound, $2 should be query, $3 should be end_bound
    # N.B. The XS version of this algorithm is only a hair faster,
    # since the $re is the bottleneck.
    while ( $$text =~ m/$re/g ) {

        if ($debug) {
            carp "$2 matches $re";
        }

        $m->{$2}++;
        pos($$text) = pos($$text) - 1;

        # move back and consider $3 again as possible $1 for next match

    }

    return $m;

}

# based on HTML::HiLiter hilite()
sub html {
    my $self = shift;
    my $text = shift or croak "need text to light()";

    ###################################################################
    # 1.	create hash of query -> [ array of real HTML to hilite ]
    # 	    using the prebuilt regexp
    # 2.    hilite the real HTML
    ###################################################################

    ## 1

    my $q2real = {};

    # this is going to be query => [ real_html ]

    # if the query text matched in the text, then we need to
    # use our prebuilt regexp
    my @kworder = $self->_kworder;

    # don't consider anything we've marked
    # with a 'nohiliter' attribute
    my $text_copy = $text;
    $text_copy =~ s/\002.*?\003//sgi;

Q: for my $query (@kworder) {
        my $re = $self->query->regex_for($query)->html;
        my $real = $self->_get_real_html( \$text_copy, $re );

    R: for my $r ( keys %$real ) {
            push( @{ $q2real->{$query} }, $r ) while $real->{$r}--;
        }
    }

    ## 2

HILITE: for my $q (@kworder) {

        my %uniq_reals = ();
        $uniq_reals{$_}++ for @{ $q2real->{$q} };

    REAL: for my $real ( keys %uniq_reals ) {

            $self->_add_hilite_tags( \$text, $q, $real );

        }

    }

    return $text;
}

sub _add_hilite_tags {
    my $self  = shift;
    my $text  = shift;    # reference
    my $query = shift;
    my $html  = shift;

    # $text is reference to original text
    # $html is the real html that matched our regexp

    # we still check boundaries just to be safe
    my $st_bound  = $self->query->qp->start_bound;
    my $end_bound = $self->query->qp->end_bound;

    my $o = $self->open_tag($query);
    my $c = $self->close_tag($query);

    my $safe = quotemeta($html);

    # pre-fix nested tags in match
    my $pre_fixed = $html;
    my $tag_re    = $self->query->qp->tag_re;
    my $pre_added = $pre_fixed =~ s(${tag_re}+)$c$1$og;
    my $len_added = length( $c . $o ) * $pre_added;

    # should be same as length( $to_hilite) - length( $prefixed );
    my $len_diff = ( length($html) - length($pre_fixed) );
    $len_diff *= -1
        if $len_diff < 0;    # pre_added might be -1 if no subs were made
    if ( $len_diff != $len_added ) {
        carp "length math failed!"
            . "len_diff = $len_diff\nlen_added = $len_added";
    }

    while ( $$text =~ m/($st_bound)($safe)($end_bound)/g ) {
        my $s = $1;
        my $m = $2;
        my $e = $3;
        if ( $self->debug > 1 ) {
            carp "matched:\n'$s'\n'$m'\n'$e'\n"
                . "\$1 is "
                . ord($s)
                . "\$3 is "
                . ord($e);
        }

        # use substr to do what s// would normally do if pos() wasn't an issue
        # -- is this a big speed hit?
        my $len       = length( $s . $m . $e );
        my $pos       = pos($$text);
        my $newstring = $s . $o . $pre_fixed . $c . $e;
        substr( $$text, $pos - $len, $len, $newstring );

        pos($$text) = $pos + length( $o . $c ) + $len_added - 1;

      # adjust for new text added
      # $pre_fixed is the hard bit, since we must take $len_added into account
      # move back 1 to reconsider $3 as next $1

#		warn "pos was $pos\nnow ", pos( $html ), "\n";
#		warn "new: '$html'\n";
#		warn "new text: '$newstring'\n";
#		warn "first chars of new pos are '", substr( $html, pos($html), 10 ), "'\n";

    }

    $self->_clean_up_hilites( $text, $query, $o, $c, $safe );

}

# no algorithm is perfect. fix it as best we can.
sub _clean_up_hilites {

    my $self = shift;
    my ( $text, $query, $o, $c, $safe ) = @_;

    # empty hilites are useless
    my $empty = ( $$text =~ s,\Q$o$c\E,,sgi ) || 0;

#$self->debug and carp "looking for split entities: (&[\\w#]*)\Q$o\E(?:\Q$c\E)(${safe})\Q$c\E([\\w#]*;)";

# to be safe: in some cases we might match against entities or within tag content.
    my $ent_split = (
        $$text
            =~ s/(&[\w#]*)\Q$o\E(?:\Q$c\E)?(${safe})\Q$c\E([\w#]*;)/$1$2$3/igs # is i and s necessary?
    ) || 0;

    #$self->debug and carp "found $ent_split split entities";

    my $tag_split = 0;
    while (
        $$text
        =~ m/(<[^<>]*)\Q$o\E($safe)\Q$c\E([^>]*>)/gxsi # are these xsi flags necessary?
        )
    {

        my $first  = $1;
        my $second = $2;
        my $third  = $3;
        carp "appears to split tag: $first - $second - $third"
            if $self->debug > 1;

       # TODO this would be one place to highlight text where attributes match

        $tag_split += (
            $$text =~ s/(<[^<>]*)\Q$o\E($safe)\Q$c\E([^>]*>)/$1$2$3/gxsi );

    }

}

# based on HTML::HiLiter plaintext()
sub plain {
    my $self = shift;
    my $text = shift or croak "need text to light()";

    my $query_obj = $self->{query};

Q: for my $query ( $self->_kworder ) {
        my $re            = $query_obj->regex_for($query)->plain;
        my $o             = $self->open_tag($query);
        my $c             = $self->close_tag($query);
        my $length_we_add = length( $o . $c ) - 1;

        $self->debug > 1
            and carp
            "plain hiliter looking for: $re against '$query' in '$text'";

        # because s// fails to find duplicate instances like 'foo foo'
        # we use a while loop and increment pos()

        # this can suck into an infinite loop because increm pos()-- results
        # in repeated match on nonwordchar: > (since we just added a tag)

        if ( $self->debug ) {
            if ( $text =~ m/\Q$query\E/i && $text !~ m/$re/ ) {
                croak "bad regex for '$query': $re";
            }
        }

        my $found_matches = 0;
        while ( $text =~ m/$re/g ) {

            my $s = $1 || '';
            my $m = $2 || $query;
            my $e = $3 || '';

            $found_matches++;

            $self->debug > 1 and carp "matched $s $m $e against $re";

            # use substr to do what s/// would normally do
            # if pos() wasn't an issue -- is this a big speed diff?
            my $len       = length( $s . $m . $e );
            my $pos       = pos($text);
            my $newstring = $s . $o . $m . $c . $e;
            substr( $text, $pos - $len, $len, $newstring );

            last if $pos == length $text;

            # need to account for all the new chars we just added
            pos($text) = $pos + $length_we_add;

        }

        $self->debug and warn "found $found_matches matches";

        # sanity check similar to Snipper->_re_snip()
        if ( !$found_matches and $text =~ m/\Q$query\E/ ) {
            $self->debug and warn "ERROR: regex failure for '$query'";
            $text = $self->html($text);
        }

    }

    #warn "plain done";

    return $text;

}

1;
__END__

=pod

=head1 NAME

Search::Tools::HiLiter - highlight terms in text

=head1 SYNOPSIS

 use Search::Tools::HiLiter; 
 my $hiliter = Search::Tools::HiLiter->new( 
    query => 'the quick brown fox' 
 );
             
 for my $text (@texts) {
    print $hiliter->light( $text );
 }

=head1 DESCRIPTION

Search::Tools::HiLiter uses HTML tags to highlight text 
just like a felt-tip HiLiter. The HiLiter can handle both 
plain (no HTML markup) and marked up text (HTML and XML). 
Nested entities and tags within terms are supported.

You create a HiLiter object with either a string
or a Search::Tools::Query object, and then feed the HiLiter
text to highlight. You can control the style and color of the highlight tags.

Some caveats if you are highlighting HTML or XML:
Unlike its more powerful cousin HTML::HiLiter, Search::Tools::HiLiter
knows nothing about context. This can give unexpected results 
when your terms appear in the HTML C<<head>> or across block tag boundaries. 
Use HTML::HiLiter if you need a real HTML parser.
It uses the same regular expressions as this class but is designed for full HTML
documents rather than smaller fragments.


=head1 METHODS

=head2 new( query => I<query> )

I<query> must be either a scalar string or a Search::Tools::Query object. 
You might use the last if you are also using Search::Tools::Snipper, 
since you only need to compile your Search::Tools::Query
object once and then pass it to both new() instances.

The following params are also supported. Each is available as an
accessor method as well:

=over

=item class

=item colors

=item no_html

=item style

=item tag

=item text_color

=item tty

=item ttycolors

=back

=head2 init

Called internally by new().

=head2 terms

Calls through to I<query>->terms(). Returns array ref.

=head2 keywords

Like terms() but returns array not array ref.

=head2 open_tag( I<term> )

Get the opening hilite tag for I<term>.

=head2 close_tag( I<term> )

Get the closing hilite tag for I<term>.

=head2 light( I<text> )

Add hiliting tags to I<text>. Calls plain() or html()
based on whether I<text> contains markup (checked with
Search::Tools::XML->looks_like_html()).

light() will return I<text> as a UTF-8 encoded string.

=head2 hilite( I<text> )

An alias for light().

=head2 plain( I<text> )

Add hiliting tags to plain I<text>.

=head2 html( I<text> )

Add hiliting tags to marked up I<text>.

=head2 class

The name of the class attribute to be used on the tag().

=head2 style

The value to use in the C<style> attribute of I<tag>.

=head2 tag

The name of the highlighting tag. Default is C<span>.

=head2 tty

Pass a true value to use Term::ANSIColor highlighting. 
This is useful when using a terminal for debugging or for displaying results. 
Default is off.

=head2 ttycolors

Set the colors used if tty() is true. 
See the Term::ANSIColor documentation for options.

=head2 debug

Set to a value >= 1 to get debugging output. 
If used in conjuction with tty(), both tty colors and HTML tags 
are used for highlighting.

=head2 no_html

Set to a true value (1) to avoid HTML highlighting tags regardless of test for whether
I<text> is HTML.

=head2 colors( I<array_ref_of_html_colors> )

Get/set the HTML color values to use inside tag(). These are used if
class() is not set. The defaults are:

 [ '#ffff99', '#99ffff', '#ffccff', '#ccccff' ]

=head2 text_color( I<html_color> )

Get/set the HTML color to set on the style attribute in tag(). This
setting can be useful if the background color of the page clashes
with one or more of the colors() (as with a black body color).

=head1 AUTHOR

Peter Karman C<< <karman at cpan dot org> >>

=head1 ACKNOWLEDGEMENTS

Based on the HTML::HiLiter regular expression building code, 
originally by the same author, copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of this module.

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::QueryParser
