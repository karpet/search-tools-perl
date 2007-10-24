package Search::Tools::RegExp::Keywords;

use 5.008_003;
use strict;
use warnings;
use Carp;

use base qw( Class::Accessor::Fast );

our $VERSION = '0.15';

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless($self, $class);
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self  = shift;
    my %extra = @_;
    @$self{keys %extra} = values %extra;

    $self->mk_ro_accessors(
        qw(
          kw
          start_bound
          end_bound
          ),
          @Search::Tools::Accessors
    );
    
    $self->{debug} ||= $ENV{PERL_DEBUG} || 0;
}

sub keywords
{
    my $self = shift;
    return @{$self->{array}};
}

sub re
{
    my $self = shift;
    my $q = shift or croak "need query to get regular expression";
    unless (exists $self->{hash}->{$q})
    {
        croak "no regexp for query '$q'";
    }
    return $self->{hash}->{$q};
}

1;

__END__

=pod

=head1 NAME

Search::Tools::RegExp::Keywords - access regular expressions for keywords

=head1 SYNOPSIS

 my $regexp = Search::Tools::RegExp->new();
 
 my $kw = $regexp->build('the quick brown fox');
 
 for my $w ($kw->keywords)
 {
    my $r = $kw->re( $w );
 }

 
 
=head1 DESCRIPTION

Search::Tools::RegExp::Keywords provides access to the regular expressions
for a query keyword.

A Search::Tools::RegExp::Keywords object is returned by the Search::Tools::RegExp
build() method. This class is typically not used in isolation.


=head1 METHODS

In addition, a Search::Tools::RegExp::Keywords object inherits from its parent
Search::Tools::RegExp object the common
accessors defined in @Search::Tools::Accessors. Since a S::T::R::Keywords object
doesn't modify anything, you should consider those common accessors as accessors
only, not mutators.

The following methods are available.

=head2 new

Create an object. Used internally.


=head2 keywords

Returns array of keywords in same order
as they appeared in the original query.

=head2 re( I<keyword> )

Returns a Search::Tools::RegExp::Keyword object corresponding to I<keyword>.

=head2 kw

Get the original S::T::Keywords object from which the object is derived.

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

HTML::HiLiter, Search::Tools::RegExp, Search::Tools::RegExp::Keyword

=cut
