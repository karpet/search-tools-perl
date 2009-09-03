package Search::Tools::TokenList;
use strict;
use warnings;
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;

use Search::Tools;    # XS required
use Carp;

our $VERSION = '0.24';

sub str {
    my $self   = shift;
    my $joiner = shift(@_);
    if ( !defined $joiner ) {
        $joiner = '';
    }
    return join( $joiner, map {"$_"} @{ $self->as_array } );
}

=head2 get_window( I<pos> [, I<size>] )

Returns array ref of positions of length I<size>
on either side of I<pos>. Like taking a slice of the TokenList,
only getting an array ref of positions rather than tokens.

=cut

sub get_window {
    my $self = shift;
    my $pos  = shift;
    if ( !defined $pos ) {
        croak "pos required";
    }

    my $size = shift || 20;
    my $max_index = $self->len - 1;

    if ( $pos > $max_index or $pos < 0 ) {
        croak "illegal pos value: no such index in TokenList";
    }

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
    return [ $start .. $end ];
}

1;
