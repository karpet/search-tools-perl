package Search::Tools::TokenList;
use strict;
use warnings;
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;

use Search::Tools;    # XS required

our $VERSION = '0.24';

sub str {
    my $self   = shift;
    my $joiner = shift(@_);
    if ( !defined $joiner ) {
        $joiner = '';
    }
    return join( $joiner, map {"$_"} @{ $self->as_array } );
}

1;
