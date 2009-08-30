package Search::Tools::Tokenizer;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Search::Tools;    # XS package required
use Carp;

our $VERSION = '0.24';

__PACKAGE__->mk_accessors(qw( re ));

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->{re} ||= qr/\w+(?:'\w+)*/;
    $self->set_debug( $self->debug );
    return $self;
}

package Search::Tools::Token;
use overload
    'cmp'    => sub { Data::Dump::dump(\@_) },
    'eq'     => sub { Data::Dump::dump(\@_) },
    '""'     => 'str',
    'bool'   => sub { Data::Dump::dump(\@_); return $_[0]->len; },
    fallback => 1;

1;
