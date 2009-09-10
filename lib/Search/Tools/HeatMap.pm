package Search::Tools::HeatMap;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Search::Tools::Object );

# debuggin only
my $OPEN  = '[';
my $CLOSE = ']';
eval "require Term::ANSIColor";
if ( !$@ ) {
    $OPEN .= Term::ANSIColor::color('bold red');
    $CLOSE = Term::ANSIColor::color('reset') . $CLOSE;
}

__PACKAGE__->mk_accessors(qw( window_size tokens hot spans ));

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->_build;
    return $self;
}

# TODO this is mostly integer math and might be much
# faster if rewritten in XS once the algorithm is "final".
sub _build {
    my $self       = shift;
    my $tokens     = $self->tokens or croak "tokens required";
    my $window     = $self->window_size || 20;
    my $lhs_window = int( $window / 2 );

    # build heatmap

    # (1) find all the hot tokens in the list
    my @hot;
    my $num_tokens = $tokens->len;
    my $tokens_arr = $tokens->as_array;
    while ( my $tok = $tokens->next ) {
        if ( $tok->is_hot ) {
            push( @hot, $tok );
        }
    }

    # (2) find all the hot tokens that are within $window
    #     positions of another hot token.
    #     i.e. hot clusters.
    my $i = 0;
    my %heatmap;

    #warn dump \@hot;
    for my $tok (@hot) {

        my $pos    = $tok->pos;
        my $weight = $tok->is_hot;
        $heatmap{$pos} += $weight;

        # grap window on either side.
        # this helps identify clusters of matches,
        # including phrases.
        # TODO likely don't need entire $window, but
        # there is likely a statistically minimum sample size.
        for ( @{ $tokens->get_window( $pos, $window ) } ) {
            $heatmap{ $_->pos } += $_->is_hot if $_->is_hot;
        }

        $i++;
    }

    # (3) make clusters
    my $match_distance = int( $num_tokens / $tokens->num_matches );
    my @positions      = sort { $a <=> $b } keys %heatmap;
    my @clusters       = ( [] );
    $i = 0;
    for my $pos (@positions) {

        # if we have advanced past the first position
        # and the previous position is not adjacent to this one,
        # start a new cluster
        if ( $i && $positions[ $i - 1 ] != ( $pos - $match_distance ) ) {
            push( @clusters, [$pos] );
        }
        else {
            push( @{ $clusters[-1] }, $pos );
        }
        $i++;
    }

    #warn "match_distance: $match_distance   clusters: " . dump \@clusters;

    # (4) create spans from each cluster, each with a weight.
    # sort by cluster length, so we get highest density first,
    # followed by heatmap value,
    # followed by lowest position (first in tokenlist).
    my @spans;
    my %seen_pos;
    $i = 0;
    for my $cluster (
        sort {
                   scalar(@$b) <=> scalar(@$a)
                || $heatmap{ $b->[0] } <=> $heatmap{ $a->[0] }
                || $a->[0] <=> $b->[0]
        } @clusters
        )
    {

        # get full window, ignoring positions we've already seen.
        my $heat = 0;
        my %span;
        my @cluster_tokens;
        for my $pos (@$cluster) {
            $heat += $heatmap{$pos};
            my $slice = $tokens->get_window( $pos, $window );
            for my $tok (@$slice) {
                next if $seen_pos{ $tok->pos }++;
                push( @cluster_tokens, $tok );
            }
        }

        # we may have skipped a $seen_pos from the $slice above
        # so make sure we still start/end on a match
        while ( @cluster_tokens && !$cluster_tokens[0]->is_match ) {
            shift @cluster_tokens;
        }
        while ( @cluster_tokens && !$cluster_tokens[-1]->is_match ) {
            pop @cluster_tokens;
        }

        # sanity: make sure we still have something hot
        my $has_hot = 0;
        for (@cluster_tokens) {
            $has_hot++ if $_->is_hot;
        }
        next unless $has_hot;
        next unless @cluster_tokens;

        $span{cluster} = $cluster;
        $span{heat}    = $heat;
        $span{pos}     = [ map { $_->pos } @cluster_tokens ];

        # TODO is the sort necessary? dump pos above
        $span{tokens} = [ sort { $a->pos <=> $b->pos } @cluster_tokens ];
        $span{str} = join( '', map { $_->str } @{ $span{tokens} } );

        # just for debug
        $span{str_w_pos} = join(
            '',
            map {
                      $_->str
                    . ( $_->is_hot ? $OPEN : '[' )
                    . $_->pos
                    . ( $_->is_hot ? $CLOSE : ']' )
                } @{ $span{tokens} }
        );

        # spans with more *unique* hot tokens in a single span rank higher
        my %uniq = ();
        for ( @{ $span{tokens} } ) {
            $uniq{ $_->str } += $_->is_hot;
        }
        $span{unique} = scalar keys %uniq;

        push @spans, \%span;

    }

    $self->{spans}   = \@spans;
    $self->{hot}     = \@hot;
    $self->{heatmap} = \%heatmap;

    return $self;
}

sub has_spans {
    return scalar @{ $_[0]->{spans} };
}

1;
