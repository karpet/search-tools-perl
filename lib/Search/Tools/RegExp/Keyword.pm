package Search::Tools::RegExp::Keyword;
use strict;
use warnings;
use Carp;
use base qw( Search::Tools::Object );

our $VERSION = '0.43';

__PACKAGE__->mk_ro_accessors(qw( plain html word phrase ));

1;
__END__

=pod

=head1 NAME

Search::Tools::RegExp::Keyword - (**DEPRECATED**) access regular expressions for a keyword

=head1 SYNOPSIS

 # deprecated. See Search::Tools::RegEx
 
=head1 DESCRIPTION

As of version 0.24 this class is deprecated in favor of Search::Tools::RegEx.

=head1 METHODS

=head2 plain

=head2 html

=head2 word

=head2 phrase

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

Based on the HTML::HiLiter regular expression building code, originally by the same author, 
copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of this module.

=head1 COPYRIGHT

Copyright 2006 by Peter Karman. 
This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

HTML::HiLiter, Search::Tools::RegExp, Search::Tools::RegExp::Keywords

=cut
