package Search::Tools::Keywords;

use strict;
use warnings;
use base qw( Search::Tools::QueryParser );

# this is backcompat class only.

sub extract {
    @{ shift->_extract_terms(@_)->{terms} };
}

1;

__END__

=pod

=head1 NAME

Search::Tools::Keywords - extract keywords from a search query

=head1 DESCRIPTION

As of version 0.24 this class is a simple subclass of Search::Tools::QueryParser.
The extract() method works as in previous versions, but you should
use Search::Tools::QueryParser instead of this class.

=head1 COPYRIGHT

Copyright 2006 by Peter Karman. 

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

HTML::HiLiter, Search::QueryParser
