package Search::Tools::Object;
use strict;
use warnings;
use Carp;
use base qw( Class::Accessor::Fast );
use Search::Tools;

=pod

=head1 NAME

Search::Tools::Object - base class for Search::Tools objects

=head1 METHODS

=head2 new( I<args> )

I<args> should be a hash.

=cut

__PACKAGE__->mk_accessors( qw( debug ) );

sub new {
    my $class = shift;
    my $self  = bless( {}, $class );
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self  = shift;
    my %extra = @_;
    @$self{ keys %extra } = values %extra;
    $self->{debug} ||= $ENV{PERL_DEBUG} || 0;
}

1;

__END__

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

=head1 COPYRIGHT

Copyright 2007 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools

=cut
