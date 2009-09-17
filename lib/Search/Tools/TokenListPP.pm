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

__END__

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

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
