package Search::Tools::HiLiter;

use 5.008;
use strict;
use warnings;
use Carp;

#use Data::Dumper;      # just for debugging
use Search::Tools::RegExp;

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
          query
          rekw
          tag
          class
          colors
          tty
          ttycolors
          no_html
          ),
        @Search::Tools::Accessors
    );

    $self->{debug} ||= $ENV{PERL_DEBUG} || 0;

    if ($self->debug)
    {
        carp "debug level set at " . $self->debug;
    }

    if (!$self->query)
    {
        croak "query required.";
    }
    elsif (ref $self->query eq 'ARRAY' or !ref $self->query)
    {
        my $re =
          Search::Tools::RegExp->new(map { $_ => $self->$_ }
                                     @Search::Tools::Accessors);
        $self->rekw($re->build($self->query));
    }
    elsif ($self->query->isa('Search::Tools::RegExp::Keywords'))
    {
        $self->rekw($self->query);
    }
    else
    {
        croak
          "query must be either a string or Search::Tools::RegExp::Keywords object";
    }

    unless ($self->rekw)
    {
        croak "Search:Tools::RegExp::Keywords object required";
    }

    $self->{tag} ||= 'span';
    $self->{colors} ||= ['#ffff99', '#99ffff', '#ffccff', '#ccccff'];
    $self->{ttycolors} ||= ['bold blue', 'bold red', 'bold green'];

    if ($self->tty)
    {
        eval { require Term::ANSIColor };
        $self->tty(0) if $@;
    }

    $self->_build_tags;

    #carp Dumper $self;

}

sub keywords
{
    my $self = shift;
    return $self->rekw->keywords;
}

sub _phrases
{
    my $self = shift;
    return grep { $self->rekw->re($_)->phrase } $self->keywords;
}

sub _singles
{
    my $self = shift;
    return grep { !$self->rekw->re($_)->phrase } $self->keywords;
}

sub _kworder
{
    my $self = shift;

    # do phrases first so that duplicates privilege phrases
    $self->{_kworder} ||= [$self->_phrases, $self->_singles];
    return @{$self->{_kworder}};
}

sub _build_tags
{
    my $self = shift;

    my $t         = {};
    my @colors    = @{$self->colors};
    my @ttycolors = @{$self->ttycolors};
    my $tag       = $self->tag;

    my $n = 0;
    my $m = 0;

    for my $q ($self->_kworder)
    {

        # if tty flag is on, use ansicolor instead of html
        # if debug flag is on, use both html and ansicolor

        my (%tags, $hO);
        $tags{open}  = '';
        $tags{close} = '';
        if ($self->class)
        {
            $hO = qq/<$tag class="/ . $self->class . qq/">/;
        }
        else
        {
            $hO = qq/<$tag style="background:/ . $colors[$n] . qq/">/;
        }

        if ($self->tty)
        {
            $tags{open} .= $hO if $self->debug && !$self->no_html;
            $tags{open}  .= Term::ANSIColor::color($ttycolors[$m]);
            $tags{close} .= Term::ANSIColor::color('reset');
            $tags{close} .= "</$tag>" if $self->debug && !$self->no_html;
        }
        else
        {
            $tags{open}  .= $hO;
            $tags{close} .= "</$tag>";
        }

        $t->{$q} = \%tags;

        $n = 0 if ++$n > $#colors;
        $m = 0 if ++$m > $#ttycolors;
    }

    $self->{_tags} = $t;
}

sub open_tag
{
    my $self = shift;
    my $q = shift or croak "need query to get open_tag";
    return $self->{_tags}->{$q}->{open} || '';
}

sub close_tag
{
    my $self = shift;
    my $q = shift or croak "need query to get close_tag";
    return $self->{_tags}->{$q}->{close} || '';
}

sub light
{
    my $self = shift;
    my $text = shift or return '';

    if (Search::Tools::RegExp->isHTML($text) && !$self->no_html)
    {
        return $self->html($text);
    }
    else
    {
        return $self->plain($text);
    }
}

sub _get_real_html
{
    my $self = shift;
    my $text = shift;
    my $re   = shift;
    my $m    = {};

    # $1 should be st_bound, $2 should be query, $3 should be end_bound

    while ($$text =~ m/$re/g)
    {

        if ($self->debug > 1)
        {
            carp "$2  matches $re";
        }

        $m->{$2}++;
        pos($$text) = pos($$text) - 1;

        # move back and consider $3 again as possible $1 for next match

    }

    return $m;

}

# based on HTML::HiLiter hilite()
sub html
{
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

  Q: for my $query ($self->_kworder)
    {
        my $re   = $self->rekw->re($query)->html;
        my $real = $self->_get_real_html(\$text, $re);

      R: for my $r (keys %$real)
        {
            push(@{$q2real->{$query}}, $r) while $real->{$r}--;
        }
    }

    ## 2

  HILITE: for my $q ($self->_kworder)
    {

        my %uniq_reals = ();
        $uniq_reals{$_}++ for @{$q2real->{$q}};

      REAL: for my $real (keys %uniq_reals)
        {

            $self->_add_hilite_tags(\$text, $q, $real);

        }

    }

    return $text;
}

sub _add_hilite_tags
{
    my $self  = shift;
    my $text  = shift;    # reference
    my $query = shift;
    my $html  = shift;

    # $text is reference to original text
    # $html is the real html that matched our regexp

    # we still check boundaries just to be safe
    my $st_bound  = $self->rekw->start_bound;
    my $end_bound = $self->rekw->end_bound;

    my $o = $self->open_tag($query);
    my $c = $self->close_tag($query);

    my $safe = quotemeta($html);

    # pre-fix nested tags in match
    my $pre_fixed = $html;
    my $pre_added = $pre_fixed =~ s($Search::Tools::RegExp::TagRE+)$c$1$og;
    my $len_added = length($c . $o) * $pre_added;

    # should be same as length( $to_hilite) - length( $prefixed );
    my $len_diff = (length($html) - length($pre_fixed));
    $len_diff *= -1
      if $len_diff < 0;    # pre_added might be -1 if no subs were made
    if ($len_diff != $len_added)
    {
        carp "length math failed!"
          . "len_diff = $len_diff\nlen_added = $len_added";
    }

    while ($$text =~ m/($st_bound)($safe)($end_bound)/g)
    {
        my $s = $1;
        my $m = $2;
        my $e = $3;
        if ($self->debug > 1)
        {

            #print "$OC add_hilite_tags:\n$st_bound\n$safe\n$end_bound\n $CC";
            carp "matched:\n'$s'\n'$m'\n'$e'\n"
              . "\$1 is "
              . ord($s)
              . "\$3 is "
              . ord($e);
        }

        # use substr to do what s// would normally do if pos() wasn't an issue
        # -- is this a big speed hit?
        my $len       = length($s . $m . $e);
        my $pos       = pos($$text);
        my $newstring = $s . $o . $pre_fixed . $c . $e;
        substr($$text, $pos - $len, $len, $newstring);

        pos($$text) = $pos + length($o . $c) + $len_added - 1;

        # adjust for new text added
        # $pre_fixed is the hard bit, since we must take $len_added into account
        # move back 1 to reconsider $3 as next $1

        #		warn "pos was $pos\nnow ", pos( $html ), "\n";
        #		warn "new: '$html'\n";
        #		warn "new text: '$newstring'\n";
        #		warn "first chars of new pos are '", substr( $html, pos($html), 10 ), "'\n";

    }

    $self->_clean_up_hilites($text, $query, $o, $c, $safe);

}

# no algorithm is perfect. fix it as best we can.
sub _clean_up_hilites
{

    my $self = shift;
    my ($text, $query, $o, $c, $safe) = @_;

    # empty hilites are useless
    my $empty = ($$text =~ s,\Q$o$c\E,,sgi) || 0;

    #$self->debug and carp "looking for split entities: (&[\\w#]*)\Q$o\E(?:\Q$c\E)(${safe})\Q$c\E([\\w#]*;)";

    # to be safe: in some cases we might match against entities or within tag content.
    my $ent_split = (
        $$text =~
          s/(&[\w#]*)\Q$o\E(?:\Q$c\E)?(${safe})\Q$c\E([\w#]*;)/$1$2$3/igs # is i and s necessary?
      )
      || 0;

    #$self->debug and carp "found $ent_split split entities";

    my $tag_split = 0;
    while (
        $$text =~
        m/(<[^<>]*)\Q$o\E($safe)\Q$c\E([^>]*>)/gxsi # are these xsi flags necessary?
          )
    {

        my $first = $1;
        my $second = $2;
        my $third = $3;
        carp "appears to split tag: $first - $second - $third" if $self->debug > 1;
        
        # TODO this would be one place to highlight text where attributes match

        $tag_split +=
          ($$text =~ s/(<[^<>]*)\Q$o\E($safe)\Q$c\E([^>]*>)/$1$2$3/gxsi);

    }

}

# based on HTML::HiLiter plaintext()
sub plain
{
    my $self = shift;
    my $text = shift or croak "need text to light()";

  Q: for my $query ($self->_kworder)
    {
        my $re = $self->rekw->re($query)->plain;
        my $o  = $self->open_tag($query);
        my $c  = $self->close_tag($query);

        $self->debug > 1 and carp "looking for: $re against $query";

        # because s// fails to find duplicate instances like 'foo foo'
        # we use a while loop and increment pos()

        # this can suck into an infinite loop because increm pos()-- results
        # in repeated match on nonwordchar: > (since we just added a tag)

        while ($text =~ m/$re/g)
        {

            my $s = $1 || '';
            my $m = $2 || $query;
            my $e = $3 || '';

            $self->debug > 1 and carp "matched $s $m $e against $re";

            # use substr to do what s// would normally do if pos() wasn't an issue
            # -- is this a big speed diff?
            my $len       = length($s . $m . $e);
            my $pos       = pos($text);
            my $newstring = $s . $o . $m . $c . $e;
            substr($text, $pos - $len, $len, $newstring);

            last if $pos == length $text;

            # need to account for all the new chars we just added with length(...)
            pos($text) = $pos + length($o . $c) - 1;

        }

    }

    return $text;

}

1;
__END__

=pod

=head1 NAME

Search::Tools::HiLiter - extract and highlight search results in original text

=head1 SYNOPSIS

 use Search::Tools::HiLiter;
 
 my $re = Search::Tools::RegExp->new;
 my $kw = $re->build('the quick brown fox');
 
 my $hiliter = Search::Tools::HiLiter->new( kw => $kw );
             
 for my $text (@texts)
 {
    print $hiliter->light( $text );
 }

=head1 DESCRIPTION

Search::Tools::HiLiter uses HTML tags to highlight text just like a felt-tip HiLiter.
S::T::H can handle both plain and marked up text (HTML and XML). 
Nested entities and tags within keywords are supported.

You create
a HiLiter object with either a string, an array of strings, or a
Search::Tools::RegExp::Keywords object, and then feed the HiLiter
text to highlight. You can control the style and color of the highlight tags.

Some caveats if you are highlighting HTML or XML:
Unlike its more powerful cousin HTML::HiLiter, S::T::H knows nothing about context.
This can give unexpected results when your keywords appear in the HTML C<<head>>
or across block tag boundaries. Use HTML::HiLiter if you need a real HTML parser.
It uses the same regular expressions as S::T::H but is designed for full HTML
documents rather than smaller fragments.


=head1 METHODS

=head2 new( query => I<query> )

I<query> must be either a scalar string, an array reference to a list of scalar strings,
or a Search::Tools::RegExp::Keywords object. You might use the last if you are also
using Search::Tools::Snipper, since you only need to compile your S::T::R::Keywords
object once and then pass it to both new() instances.

The following params are also supported. Each is available as a method as well:

=over

=item class

=item tag

=item colors

=item tty

=item ttycolors

=item no_html

=back

=head2 open_tag( I<keyword> )

=head2 close_tag( I<keyword> )

=head2 light( I<text> )

=head2 plain( I<text> )

=head2 html( I<text> )


=head2 class

The name of the class attribute to be used on the tag().

=head2 tag

The name of the highlighting tag. Default is C<span>.

=head2 tty

Pass a true value to use Term::ANSIColor highlighting. This is useful when using
a terminal for debugging or for displaying results. Default is off.

=head2 ttycolors

Set the colors used if tty() is true. See the Term::ANSIColor documentation for options.

=head2 debug

Set to a value >= 1 to get debugging output. If used in conjuction with tty(), both
tty colors and HTML tags are used for highlighting.

=head2 no_html

Set to a true value (1) to avoid HTML highlighting tags regardless of test for whether
I<text> is HTML.

=head2 keywords

Returns the keywords derived from I<query>.

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

HTML::HiLiter, Search::Tools::RegExp::Keywords

=cut
