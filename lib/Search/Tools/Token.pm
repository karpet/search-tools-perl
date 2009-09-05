package Search::Tools::Token;
use strict;
use warnings;
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub { $_[0]->len; },
    fallback => 1;

use Search::Tools;    # XS required

our $VERSION = '0.24';

sub is_end_of_sentence {
    return $_[0] =~ m/[\.\?\!\;\:]\ /;
}

1;
