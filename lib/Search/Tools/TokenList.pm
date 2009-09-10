package Search::Tools::TokenList;
use strict;
use warnings;
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;

use Search::Tools;    # XS required
use Carp;
use base qw( Search::Tools::TokenListUtils );

our $VERSION = '0.24';

1;
