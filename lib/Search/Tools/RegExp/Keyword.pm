package Search::Tools::RegExp::Keyword;
use strict;
use warnings;
use Carp;
use base qw( Search::Tools::Object );

our $VERSION = '0.22';

__PACKAGE__->mk_ro_accessors(qw( plain html word phrase ));

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
}

1;
__END__

=pod

=head1 NAME

Search::Tools::RegExp::Keyword - access regular expressions for a keyword

=head1 SYNOPSIS

 my $regexp = Search::Tools::RegExp->new();
 
 my $kw = $regexp->build('the quick brown fox');
 
 for my $w ($kw->keywords)
 {
    my $re = $kw->re( $w ); # $re is S::T::R::Keyword object
    
    # each of these are regular expressions ... suitable for framing
    my $h = $re->html;
    my $p = $re->plain;
    unless ( $re->word =~ m/^$h$/ )
    {
        die "something terribly wrong with the html regexp: $h";
    }
    unless ( $re->word =~ m/^$p$/ )
    {
        die "something terribly wrong with the plain regexp: $p";
    }
 }
 
 
=head1 DESCRIPTION

Search::Tools::RegExp::Keyword provides access to the regular expressions
for a query keyword.


=head1 METHODS

=head2 new

Create an object. Used internally.

=head2 word

Returns the original keyword on which the regular expressions are based.

=head2 phrase

Returns true if the keyword was treated as a phrase.

=head2 plain

Returns a regular expression for matching the keyword in a plain text
(no HTML or XML markup).

=head2 html

Returns a regular expression for matching the keyword in a HTML or XML
text.

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
