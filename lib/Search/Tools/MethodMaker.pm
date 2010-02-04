package Search::Tools::MethodMaker;
use strict;
use warnings;
use Carp;

#use Data::Dump qw( dump );
use base qw( Rose::ObjectX::CAF::MethodMaker );

our $VERSION = '0.43';

=head1 NAME

Search::Tools::MethodMaker - Class::Accessor::Fast-compatible accessors

=head1 DESCRIPTION

Search::Tools::MethodMaker is used internally by Search::Tools::Object.

=head1 METHODS

Search::Tools::MethodMaker is a subclass of Rose::ObjectX::CAF::MethodMaker
and currently implements no methods.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Rose::Object
