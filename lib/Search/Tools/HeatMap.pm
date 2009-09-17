package Search::Tools::HeatMap;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Search::Tools::Object );

our $VERSION = '0.24';

# debuggin only
my $OPEN  = '[';
my $CLOSE = ']';
eval "require Term::ANSIColor";
if ( !$@ ) {
    $OPEN .= Term::ANSIColor::color('bold red');
    $CLOSE = Term::ANSIColor::color('reset') . $CLOSE;
}

__PACKAGE__->mk_accessors(qw( window_size tokens spans ));

=head1 NAME

Search::Tools::HeatMap - locate the best matches in a snippet extract

=head1 SYNOPSIS

 use Search::Tools::Tokenizer;
 use Search::Tools::HeatMap;
     
 my $tokens = $self->tokenizer->tokenize( $my_string, qr/^(interesting)$/ );
 my $heatmap = Search::Tools::HeatMap->new(
     tokens      => $tokens,
     window_size => 20,
 );

 if ( $heatmap->has_spans ) {
 
     my $tokens_arr = $tokens->as_array;

     # stringify positions
     my @snips;
     for my $span ( @{ $heatmap->spans } ) {
         push( @snips, $span->{str} );
     }
     my $occur_index = $self->occur - 1;
     if ( $#snips > $occur_index ) {
         @snips = @snips[ 0 .. $occur_index ];
     }
     printf("%s\n", join( ' ... ', @snips ));
     
 }

=head1 DESCRIPTION

Search::Tools::HeatMap implements a simple algorithm for locating
the densest clusters of unique, hot terms in a TokenList.

HeatMap is used internally by Snipper but documented here in case
someone wants to abuse and/or improve it.

=head1 METHODS

=head2 new( tokens => I<TokenList> )

Create a new HeatMap. The I<TokenList> object may be either a
Search::Tools::TokenList or Search::Tools::TokenListPP object.

=head2 init

Builds the HeatMap object. Called internally by new().

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->_build;
    return $self;
}

=head2 window_size

The max width of a span. Defaults to 20 tokens, including the
matches.

Set this in new(). Access it later if you need to, but the spans
will have already been created by new().

=head2 spans

Returns an array ref of matching clusters. Each span in the array
is a hash ref with the following keys:

=over

=item cluster

=item pos

=item heat

=item str

=item str_w_pos

=item unique

=back

=cut

# TODO this is mostly integer math and might be much
# faster if rewritten in XS once the algorithm is "final".
sub _build {
    my $self       = shift;
    my $tokens     = $self->tokens or croak "tokens required";
    my $window     = $self->window_size || 20;
    my $lhs_window = int( $window / 2 );

    # build heatmap
    my $num_tokens      = $tokens->len;
    my $tokens_arr      = $tokens->as_array;
    my %heatmap         = ();
    my $token_list_heat = $tokens->get_heat;
    for (@$token_list_heat) {
        my $token = $tokens->get_token($_);
        $heatmap{ $token->pos } = $token->is_hot;
    }

    # make clusters
    my $match_distance = int( $num_tokens / $tokens->num_matches );
    my @positions      = sort { $a <=> $b } keys %heatmap;
    my @clusters       = ( [] );
    my $i              = 0;
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

    # create spans from each cluster, each with a weight.
    # sort by cluster length, so we get highest density first,
    # followed by heatmap value,
    # followed by lowest position (first in tokenlist).
    my @spans;
    my %seen_pos;
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
            my ( $start, $end ) = $tokens->get_window( $pos, $window );
            for my $pos2 ( $start .. $end ) {
                next if $seen_pos{$pos2}++;
                push( @cluster_tokens, $tokens->get_token($pos2) );
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

        next unless @cluster_tokens;

        # sanity: make sure we still have something hot
        my $has_hot = 0;
        my @cluster_pos;
        my @strings;
        for (@cluster_tokens) {
            my $pos = $_->pos;
            $has_hot++ if exists $heatmap{$pos};
            push @strings,     $_->str;
            push @cluster_pos, $pos;
        }
        next unless $has_hot;

        $span{cluster} = $cluster;
        $span{heat}    = $heat;
        $span{pos}     = \@cluster_pos;
        $span{tokens}  = \@cluster_tokens;
        $span{str}     = join( '', @strings );

        # just for debug
        my $i = 0;
        $span{str_w_pos} = join(
            '',
            map {
                      $strings[ $i++ ]
                    . ( exists $heatmap{$_} ? $OPEN : '[' )
                    . $_
                    . ( exists $heatmap{$_} ? $CLOSE : ']' )
                } @cluster_pos
        );

        # spans with more *unique* hot tokens in a single span rank higher
        my %uniq = ();
        $i = 0;
        for (@cluster_pos) {
            if ( exists $heatmap{$_} ) {
                $uniq{ $strings[$i] } += $heatmap{$_};
            }
            $i++;
        }
        $span{unique} = scalar keys %uniq;

        push @spans, \%span;

    }

    $self->{spans}   = \@spans;
    $self->{heatmap} = \%heatmap;

    return $self;
}

=head2 has_spans

Returns the number of spans found.

=cut

sub has_spans {
    return scalar @{ $_[0]->{spans} };
}

1;

__END__

=head1 AUTHOR

Peter Karman C<< <karman at cpan dot org> >>

=head1 ACKNOWLEDGEMENTS

The idea of the HeatMap comes from KinoSearch, though the implementation
here is original.

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

KinoSearch
