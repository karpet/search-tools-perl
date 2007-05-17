package Search::Tools;

use 5.8.3;
use strict;
use warnings;
use Carp;

our $VERSION = '0.09';

use XSLoader;
XSLoader::load('Search::Tools', $VERSION);

# accessors that every object should inherit from its parent
our @Accessors = qw(
    stopwords
    wildcard
    word_characters
    ignore_first_char
    ignore_last_char
    stemmer
    phrase_delim
    ignore_case
    debug
    locale
    charset
    lang
    
    );

sub regexp
{
    my $class = shift;
    my %extra = @_;
    my $q     = delete($extra{query}) || croak "need query to build regexp";
    require Search::Tools::RegExp;
    return Search::Tools::RegExp->new(%extra)->build($q);
}

sub hiliter
{
    my $class = shift;
    require Search::Tools::HiLiter;
    return Search::Tools::HiLiter->new(@_);
}

sub snipper
{
    my $class = shift;
    require Search::Tools::Snipper;
    return Search::Tools::Snipper->new(@_);
}

sub transliterate
{
    my $class = shift;
    require Search::Tools::Transliterate;
    return Search::Tools::Transliterate->new->convert(@_);
}

sub spellcheck
{
    my $class = shift;
    require Search::Tools::SpellCheck;
    return Search::Tools::SpellCheck->new(@_);
}

1;

__END__

=pod

=head1 NAME

Search::Tools - tools for building search applications

=head1 SYNOPSIS

 use Search::Tools;
 
 my $query = 'the quik brown fox';
 
 my $re = Search::Tools->regexp(query => $query);
 
 my $snipper    = Search::Tools->snipper(query => $re);
 my $hiliter    = Search::Tools->hiliter(query => $re);
 my $spellcheck = Search::Tools->spellcheck(query => $re);

 my $suggestions = $spellcheck->suggest($query);
 
 for my $s (@$suggestions)
 {
    if (! $s->{suggestions})
    {
        # $s->{word} was spelled correctly
    }
    elsif (@{ $s->{suggestions} })
    {
        print "Did you mean: " . join(' or ', @{$s->{suggestions}}) . "\n";
    }
 }

 for my $result (@search_results)
 {
    print $hiliter->light( $snipper->snip( $result->summary ) );
 }
  
 
=head1 DESCRIPTION

Search::Tools is a set of utilities for building search applications.
Rather than adhering to a particular search application, the goal
of Search::Tools is to provide general-purpose methods for common
search application features. Think of Search::Tools like a toolbox
rather than a hammer.

Examples include:

=over

=item

Parsing search queries for the meaningful keywords

=item

Rich regular expressions for locating keywords in the original
indexed documents

=item

Contextual snippets showing query keywords

=item

Highlighting of keywords in context

=item

Spell check keywords and suggestions of alternate spellings.

=back

Search::Tools is derived from some of the features in HTML::HiLiter
and SWISH::HiLiter, but has been re-written with an eye to accomodating
more general purpose features.

=head1 REQUIREMENTS

Perl 5.8 or later is required. This is for full UTF-8 support.

The following CPAN modules are required:

=over

=item Class::Accessor::Fast

=item Search::QueryParser

=item Text::Aspell

=back

See also the specific module documentation for individual requirements.


=head1 METHODS

=head2 transliterate( I<text> )

See Search::Tools::Transliterate convert().

The following convenience methods are simple class methods around the 
indicated module. Each of them requires a C<query> key/value pair
parameter.

=head2 regexp

=head2 snipper

=head2 hiliter

=head2 spellcheck

=head1 COMMON ACCESSORS

The following common accessors are inherited by every module in Search::Tools:

    stopwords
    wildcard
    word_characters
    ignore_first_char
    ignore_last_char
    stemmer
    phrase_delim
    ignore_case
    debug
    locale
    charset
    lang

See each module's documentation for more details.

=head1 EXAMPLES

See the tests in t/ for examples.
 
=head1 AUTHOR

Peter Karman C<perl@peknet.com>

Based on the HTML::HiLiter regular expression building code, originally by the same author, 
copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of these modules.

=head1 COPYRIGHT

Copyright 2006 by Peter Karman. 
This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

HTML::HiLiter, SWISH::HiLiter, Search::Tools::Keywords,  Search::Tools::RegExp,
Search::Tools::RegExp::Keywords, Search::Tools::RegExp::Keyword, Search::Tools::Snipper,
Search::Tools::HiLiter, Search::Tools::SpellCheck

=cut
