package Search::Tools::MethodMaker;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Rose::Object::MakeMethods::Generic );
my $Debug = 0; #$ENV{PERL_DEBUG};

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
