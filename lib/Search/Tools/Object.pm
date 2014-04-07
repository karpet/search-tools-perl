package Search::Tools::Object;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( blessed );
use Class::XSAccessor;

__PACKAGE__->mk_accessors(qw( debug ));

our $VERSION = '0.99_01';

=pod

=head1 NAME

Search::Tools::Object - base class for Search::Tools objects

=head1 SYNOPSIS

 package MyClass;
 use base qw( Search::Tools::Object );
 
 __PACKAGE__->mk_accessors( qw( foo bar ) );
 
 sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # do stuff to set up object
    
 }
 
 1;
 
 # elsewhere
 
 use MyClass;
 my $object = MyClass->new;
 $object->foo(123);
 print $object->bar . "\n";

=head1 DESCRIPTION

Search::Tools::Object uses Class::XSAccessor. 

Prior to version 1.00 STO was a subclass of Rose::ObjectX::CAF.

Prior to version 0.24 STO was a subclass of Class::Accessor::Fast. 

Backwards compatability for the mk_accessors() and mk_ro_accessors() 
class methods are preserved.

=head1 METHODS

=cut

sub _init {
    croak "use init() instead";
}

=head2 new( I<args> )

Constructor. Do not override this method. Override init() instead.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init( @_ > 1 ? @_ : %{ $_[0] } );
    return $self;
}

=head2 init

Initialize objects. Override init() instead of new(). Rather than calling
the method name for each param passed in new(), the value
is simply set in the object as a hash ref. This assumes
every Search::Tools::Object is a blessed hash ref.

The reason the hash is preferred over the method call
is to support read-only accessors, which will croak
if init() tried to set values with them.

=cut

sub init {
    my $self = shift(@_);
    $self->__init(@_);
    $self->{debug} ||= $ENV{PERL_DEBUG} || 0;
    return $self;
}

sub __init {
    my $self = shift;

    # assume object is hash and set key
    # rather than call method, since we have read-only methods.
    while (@_) {
        my $method = shift;
        if ( !$self->can($method) ) {
            croak "No such method $method";
        }
        $self->{$method} = shift;
    }

    return $self;
}

=head2 mk_accessors( I<names> )

CAF-like method for back-compat with versions < 1.00.

=cut

sub mk_accessors {
    my $class = shift;
    for my $attr (@_) {
        Class::XSAccessor->import(
            accessors => { $attr => $attr },
            class     => $class,
        );
    }
}

=head2 mk_ro_accessors( I<names> )

CAF-like method for back-compat with versions < 1.00.

=cut

sub mk_ro_accessors {
    my $class = shift;
    for my $attr (@_) {
        Class::XSAccessor->import(
            getters => { $attr => $attr },
            class   => $class,
        );
    }
}

=head2 debug( I<n> )

Get/set the debug value for the object. All objects inherit this attribute.
You can use the C<PERL_DEBUG> env var to set this value as well.

=cut

# called by some subclasses
sub _normalize_args {
    my $self  = shift;
    my %args  = @_;
    my $q     = delete $args{query};
    my $debug = delete $args{debug};
    if ( !defined $q ) {
        croak "query required";
    }
    if ( !ref($q) ) {
        require Search::Tools::QueryParser;
        $args{query} = Search::Tools::QueryParser->new(
            debug => $debug,
            map { $_ => delete $args{$_} }
                grep { Search::Tools::QueryParser->can($_) } keys %args
        )->parse($q);
    }
    elsif ( ref($q) eq 'ARRAY' ) {
        carp "query ARRAY ref deprecated as of version 0.24";
        require Search::Tools::QueryParser;
        $args{query} = Search::Tools::QueryParser->new(
            debug => $debug,
            map { $_ => delete $args{$_} }
                grep { Search::Tools::QueryParser->can($_) } keys %args
        )->parse( join( ' ', @$q ) );
    }
    elsif ( blessed($q) and $q->isa('Search::Tools::Query') ) {
        $args{query} = $q;
    }
    else {
        croak
            "query param required to be a scalar string or Search::Tools::Query object";
    }
    $args{debug} = $debug;    # restore so it can be passed on
    return %args;
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

=head1 SEE ALSO

Search::QueryParser
