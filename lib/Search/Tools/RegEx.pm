package Search::Tools::RegEx;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Carp;

#use Data::Dump qw( dump );

our $VERSION = '0.24';

__PACKAGE__->mk_ro_accessors(
    qw(
        plain
        html
        term
        is_phrase
        )
);

1;
