package Search::Tools::Object;
use strict;
use warnings;
use Carp;
use base qw( Rose::ObjectX::CAF );
use Scalar::Util qw( blessed );
use Search::Tools::MethodMaker;

our $VERSION = '0.34';

__PACKAGE__->mk_accessors(qw( debug ));

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

Search::Tools::Object is a subclass of Rose::Object. Prior to version 0.24
STO was a subclass of Class::Accessor::Fast. Backwards compatability for
the mk_accessors() and mk_ro_accessors() class methods are preserved
via Search::Tools::MethodMaker.

=head1 METHODS

=cut

sub _init {
    croak "use init() instead";
}

=head2 init

Overrides base Rose::Object method. Rather than calling
the method name for each param passed in new(), the value
is simply set in the object as a hash ref. This assumes
every Search::Tools::Object is a blessed hash ref.

The reason the hash is preferred over the method call
is to support read-only accessors, which will croak
if init() tried to set values with them.

=cut

sub init {
    #Carp::cluck();
    my $self = shift;
    #Carp::carp("self shifted");
    $self->SUPER::init(@_);
    #Carp::carp("self inited");
    $self->{debug} ||= $ENV{PERL_DEBUG} || 0;
    #Carp::carp("debug set");
    return $self;
}

=head2 debug( I<n> )

Get/set the debug value for the object. All objects inherit this attribute.
You can use the C<PERL_DEBUG> env var to set this value as well.

=cut

# called by some subclasses
sub _normalize_args {
    my $self = shift;
    my %args = @_;
    my $q    = delete $args{query};
    if ( !defined $q ) {
        croak "query required";
    }
    if ( !ref($q) ) {
        require Search::Tools::QueryParser;
        $args{query} = Search::Tools::QueryParser->new(
            map { $_ => delete $args{$_} }
            grep { Search::Tools::QueryParser->can($_) } keys %args
        )->parse($q);
    }
    elsif ( ref($q) eq 'ARRAY' ) {
        warn "query ARRAY ref deprecated as of version 0.24";
        $args{query} = Search::Tools::QueryParser->new(
            map { $_ => delete $args{$_} }
            grep { Search::Tools::QueryParser->can($_) } keys %args
        )->parse( join( ' ', @$q ) );
    }
    elsif ( blessed($q) and $q->isa('Search::Tools::Query') ) {
        $args{query} = $q;
    }
    elsif ( blessed($q) and $q->isa('Search::Tools::RegExp::Keywords') ) {

        # backcompat
        $args{query} = Search::Tools::Query->from_regexp_keywords($q);
    }
    else {
        croak
            "query param required to be a scalar string or Search::Tools::Query object";
    }
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
