package Search::Tools::RegExp::Keywords;

use 5.006;
use strict;
use warnings;
use Carp;

use base qw( Class::Accessor::Fast );

our $VERSION = '0.01';

sub new
{
    my $class = shift;
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
        qw/
          wildcard
          word_characters
          begin_characters
          end_characters
          ignore_first_char
          ignore_last_char
          start_bound
          end_bound
          kw
          /
    );
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

 my $re = Search::Tools::RegExp->new();
 
 my $kw = $re->build('the quick brown fox');
 # $kw is a S::T::R::Keywords object
 
 for my $w ($kw->keywords)
 {
    my $re = $kw->re( $w ); # $re is S::T::R::Keyword object
    
    # each of these are regular expressions ... suitable for framing
    my $h = $re->html;
    my $p = $re->plain;
 }
 
 
=head1 DESCRIPTION

Search::Tools::RegExp::Keywords provides access to the regular expressions
for a query keyword.


=head1 METHODS


=head2 new

Instantiate an object. This method is used internally by Search::Tools::RegExp->build().

=head2 keywords

Returns array of keywords in same order
as they appeared in the original query.

=head2 re( I<keyword> )

Returns a Search::Tools::RegExp::Keyword object corresponding to I<keyword>.

=head2 wildcard

The wildcard character used in constructing the regular expressions. This
value is inherited from S::T::RegExp.

=head2 word_characters

The regular expression class used in constructing the regular expressions. This
value is inherited from S::T::RegExp.

=head2 ignore_first_char

The regular expression class used in constructing the regular expressions. This
value is inherited from S::T::RegExp.

=head2 ignore_last_char

The regular expression class used in constructing the regular expressions. This
value is inherited from S::T::RegExp.

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
