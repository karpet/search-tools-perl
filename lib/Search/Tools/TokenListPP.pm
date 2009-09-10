package Search::Tools::TokenListPP;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;
use Carp;
use base qw( Search::Tools::TokenListUtils );

our $VERSION = '0.24';

__PACKAGE__->mk_accessors(qw( pos num tokens ));

sub len {
    return scalar @{ $_[0]->{tokens} };
}

sub next {
    my $self   = shift;
    my $tokens = $self->{tokens};
    my $len    = scalar(@$tokens) - 1;
    if ( $len == -1 ) {
        return undef;
    }
    elsif ( $self->{pos} > $len ) {
        return undef;
    }
    else {
        return $tokens->[ $self->{pos}++ ];
    }
}

sub prev {
    my $self   = shift;
    my $tokens = $self->{tokens};
    my $len    = scalar(@$tokens) - 1;
    if ( $len == -1 ) {
        return undef;
    }
    elsif ( $self->{pos} < 0 ) {
        return undef;
    }
    else {
        return $tokens->[ --$self->{pos} ];
    }
}

sub reset {
    $_[0]->{pos} = 0;
}

sub set_pos {
    $_[0]->{pos} = $_[1];
}

sub get_token {
    my $self = shift;
    my $len  = scalar( @{ $self->{tokens} } ) - 1;
    my $i    = shift;
    if ( !defined $i ) {
        croak "index position required";
    }
    if ( !defined $self->{tokens}->[$i] ) {
        return undef;
    }
    else {
        return $self->{tokens}->[$i];
    }
}

sub as_array {
    return $_[0]->{tokens};
}

sub matches {
    return [ grep { $_->{is_match} } @{ $_[0]->{tokens} } ];
}

sub num_matches {
    return scalar @{ shift->matches };
}

1;
