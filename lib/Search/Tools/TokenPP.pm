package Search::Tools::TokenPP;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Carp;
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;

our $VERSION = '0.24';

__PACKAGE__->mk_accessors(qw( is_match is_hot pos str len u8len ));

sub set_hot   { $_[0]->is_hot( $_[1] ); }
sub set_match { $_[0]->is_match( $_[1] ); }

sub is_end_of_sentence {
    return $_[0] =~ m/[\.\?\!\;\:]\ /;
}

1;
