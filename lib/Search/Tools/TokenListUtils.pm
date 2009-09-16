package Search::Tools::TokenListUtils;
use strict;
use warnings;
use Carp;

sub str {
    my $self   = shift;
    my $joiner = shift(@_);
    if ( !defined $joiner ) {
        $joiner = '';
    }
    return join( $joiner, map {"$_"} @{ $self->as_array } );
}

=head2 get_window( I<pos> [, I<size>] )

Returns array ref of Token objects of length I<size>
on either side of I<pos>. Like taking a slice of the TokenList,
only getting an array ref of positions rather than tokens.

Note that I<size> is the number of B<tokens> not B<matches>.
So if you're looking for the number of "words", think about
I<size>*2.

Note too that I<size> is the number of B<tokens> on B<one>
side of I<pos>. So the entire window width (length of the returned
slice) is I<size>*2 +/-1. The window is guaranteed to be bounded
by B<matches>.

=cut

sub get_window {
    my $self = shift;
    my $pos  = shift;
    if ( !defined $pos ) {
        croak "pos required";
    }

    my $size = int(shift) || 20;
    my $max_index = $self->len - 1;

    if ( $pos > $max_index or $pos < 0 ) {
        croak "illegal pos value: no such index in TokenList";
    }

    #warn "window size $size for pos $pos";

    # get the $size tokens on either side of $tok
    my ( $start, $end );

    # is token too close to the top of the stack?
    if ( $pos > $size ) {
        $start = $pos - $size;
    }

    # is token too close to the bottom of the stack?
    if ( $pos < ( $max_index - $size ) ) {
        $end = $pos + $size;
    }
    $start ||= 0;
    $end   ||= $max_index;

    # make sure window starts and ends with is_match
    while ( !$self->get_token($start)->is_match ) {
        $start++;
    }
    while ( !$self->get_token($end)->is_match ) {
        $end--;
    }

    #warn "return $start .. $end";
    #warn "$size ~~ " . ( $end - $start );

    return ($start, $end);
}

sub get_window_tokens {
    my $self = shift;
    my ( $start, $end ) = $self->get_window(@_);
    my @slice = ();
    for ( $start .. $end ) {
        push( @slice, $self->get_token($_) );
    }
    return \@slice;
}

1;

