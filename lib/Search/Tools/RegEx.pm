package Search::Tools::RegEx;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Carp;

#use Data::Dump qw( dump );

our $VERSION = '0.34';

__PACKAGE__->mk_ro_accessors(
    qw(
        plain
        html
        term
        is_phrase
        )
);

=head1 NAME

Search::Tools::RegEx - regular expressions for terms

=head1 SYNOPSIS

 my $regex = $query->regex_for('foo');
 like( 'foo', $regex->plain, "matches plain (no markup)");
 like( 'foo', $regex->html,  "matches html (with markup)");
 ok( ! $regex->is_phrase, "foo is not a phrase");
 is( 'foo', $regex->term, "foo is the term");

=head1 DESCRIPTION


=head1 METHODS

=head2 plain

=head2 html

=head2 term

=head2 is_phrase

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

Search::Tools::Query
