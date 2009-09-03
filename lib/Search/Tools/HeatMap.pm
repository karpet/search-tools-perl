package Search::Tools::HeatMap;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Search::Tools::Object );

__PACKAGE__->mk_accessors(qw( window_size tokens positions hot spans ));

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    my $tokens = $self->tokens or croak "tokens required";
    my $window = $self->window_size || 10;

    # build heatmap
    my @hot;
    my $max_index  = $tokens->len - 1;
    my $tokens_arr = $tokens->as_array;
    while ( my $tok = $tokens->next ) {
        if ( $tok->is_hot ) {
            push( @hot, $tok );
        }
    }
    my $i = 0;
    my %heatmap;

    #warn dump \@hot;
    for my $tok (@hot) {

        my $pos    = $tok->pos;
        my $weight = $tok->is_hot;
        $heatmap{$pos} += $weight;

        # if the next $pos after this is < $window
        # then flip all the hot bits on for the range
        my $max = $pos + $window;
        if ( $max > $max_index ) {
            $max = $max_index;
        }

        #warn "\$i = $i  \$max = $max";
        if ( $i < $#hot && $hot[ $i + 1 ]->pos < $max ) {
            my $pos_copy = $pos;
            while ( $pos_copy++ < $max ) {
                $heatmap{$pos_copy} += $tokens_arr->[$pos_copy]->is_hot;
            }
        }
        else {

            # grap window on either side
            for ( @{ $tokens->get_window( $pos, $window ) } ) {
                $heatmap{$_} += $tokens_arr->[$_]->is_hot;
            }

        }

        $i++;
    }

    my @positions = sort { $a <=> $b } keys %heatmap;

    #warn dump \@positions;

    my @spans = ( {} );
    $i = 0;
    for (@positions) {
        if ( $i && $positions[ $i - 1 ] != $_ - 1 ) {

            # start a new span
            push( @spans, { weight => $heatmap{$_}, 'pos' => [$_] } );
        }
        else {
            push( @{ $spans[-1]->{pos} }, $_ );
            $spans[-1]->{weight} += $heatmap{$_};
        }
        $i++;
    }

    # compute scores and stringify
    for my $span (@spans) {

        # TODO this needs some thought.
        # what is most helpful? greater length? or greater density?
        $span->{score}
            = ( $span->{weight} / scalar( @{ $span->{pos} } ) ) * 10;
        $span->{str}
            = join( '', map { $tokens_arr->[$_]->str } @{ $span->{pos} } );
    }

    #warn dump \@spans;

    $self->{positions} = \@positions;
    $self->{spans}     = [ sort { $b->{score} <=> $a->{score} } @spans ];
    $self->{hot}       = \@hot;
    $self->{heatmap}   = \%heatmap;

}

sub has_spans {
    return scalar @{ $_[0]->{spans}->[0]->{pos} };
}

1;
