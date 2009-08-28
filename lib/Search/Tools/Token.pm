package Search::Tools::Token;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Search::Tools;    # XS package required
use Carp;

our $VERSION = '0.24';

__PACKAGE__->mk_accessors(qw( str len offset prev ));

1;
