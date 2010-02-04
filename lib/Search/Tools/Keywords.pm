package Search::Tools::Keywords;

use strict;
use warnings;
use base qw( Search::Tools::QueryParser );

our $VERSION = '0.43';

# this is backcompat class only.

sub extract {
    my $self = shift;
    my $res  = $self->_extract_terms(@_);
    $self->{search_queryparser} = $res->{search_queryparser};
    $self->{query}              = $res->{query};
    return @{ $res->{terms} };
}

1;

__END__

=pod

=head1 NAME

Search::Tools::Keywords - (**DEPRECATED**) extract keywords from a search query

=head1 SYNOPSIS

 # deprecated. See Search::Tools::QueryParser
 
=head1 DESCRIPTION

As of version 0.24 this class is a simple subclass of Search::Tools::QueryParser.
The extract() method works as in previous versions, but you should
use Search::Tools::QueryParser instead of this class.

=head1 METHODS

=head2 extract( I<str> )

Returns array of key words from I<str>.

=head1 COPYRIGHT

Copyright 2009 by Peter Karman. 

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools::QueryParser
