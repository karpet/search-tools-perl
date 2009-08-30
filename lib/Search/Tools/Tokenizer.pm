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

{

    # we overload some common operators to call the XS methods
    package    # hide package from CPAN
        Search::Tools::Token;
    use overload
        'cmp'    => sub { $_[0]->cmp( $_[1] ); },
        'eq'     => sub { $_[0]->equals( $_[1] ); },
        '""'     => sub { $_[0]->str; },
        'bool'   => sub { $_[0]->len; },
        fallback => 1;
}

1;
