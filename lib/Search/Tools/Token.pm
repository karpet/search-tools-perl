package Search::Tools::Token;
use strict;
use warnings;
use overload
    'cmp'    => sub { $_[0]->cmp( $_[1] ); },
    'eq'     => sub { $_[0]->equals( $_[1] ); },
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;

use Search::Tools;    # XS required

our $VERSION = '0.24';

1;
