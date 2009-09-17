package Search::Tools::MethodMaker;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Rose::Object::MakeMethods::Generic );
my $Debug = 0;    #$ENV{PERL_DEBUG};

our $VERSION = '0.24';

=head1 NAME

Search::Tools::MethodMaker - Class::Accessor::Fast-compatible accessors

=head1 DESCRIPTION

Search::Tools::MethodMaker is used internally by Search::Tools::Object.

=head1 METHODS

Search::Tools::MethodMaker implements one method.

=head2 scalar

Overrides the Rose::Object::MakeMethods::Generic method of the same name
to provide read-only accessors like mk_ro_accessors().

=cut

# extend for mk_ro_accessors support
sub scalar {
    my ( $class, $name, $args ) = @_;

    #$Debug and dump \@_;

    my %methods;

    my $key       = $args->{'hash_key'}  || $name;
    my $interface = $args->{'interface'} || 'get_set';

    if ( $interface eq 'get_set_init' ) {
        my $init_method = $args->{'init_method'} || "init_$name";

        $methods{$name} = sub {
            return $_[0]->{$key} = $_[1] if ( @_ > 1 );

            return defined $_[0]->{$key}
                ? $_[0]->{$key}
                : ( $_[0]->{$key} = $_[0]->$init_method() );
            }
    }
    elsif ( $interface eq 'get_set' ) {
        if ( $Rose::Object::MakeMethods::Generic::Have_CXSA
            && !$ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'} )
        {
            $methods{$name} = {
                make_method => sub {
                    my ( $name, $target_class, $options ) = @_;

                    $Debug
                        && warn
                        "Class::XSAccessor make method ($name => $key) in $target_class\n";

                    Class::XSAccessor->import(
                        accessors => { $name => $key },
                        class     => $target_class,
                        replace => $options->{'override_existing'} ? 1 : 0
                    );
                },
            };
        }
        else {
            $methods{$name} = sub {
                return $_[0]->{$key} = $_[1] if ( @_ > 1 );
                return $_[0]->{$key};
                }
        }
    }
    elsif ( $interface eq 'ro' ) {
        if ( $Rose::Object::MakeMethods::Generic::Have_CXSA
            && !$ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'} )
        {
            $methods{$name} = {
                make_method => sub {
                    my ( $name, $target_class, $options ) = @_;

                    $Debug
                        && warn
                        "Class::XSAccessor make method ($name => $key) in $target_class\n";

                    Class::XSAccessor->import(
                        getters => { $name => $key },
                        class   => $target_class,
                        replace => $options->{'override_existing'} ? 1 : 0
                    );
                },
            };
        }
        else {
            $methods{$name} = sub {
                return $_[0]->{$key} = $_[1] if ( @_ > 1 );
                return $_[0]->{$key};
                }
        }
    }
    else { Carp::croak "Unknown interface: $interface" }

    return \%methods;
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

Rose::Object
