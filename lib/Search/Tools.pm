package Search::Tools;
use 5.008_003;
use strict;
use warnings::register;
use Carp;

our $VERSION = '0.24';

use XSLoader;
XSLoader::load( 'Search::Tools', $VERSION );

sub parser {
    my $class = shift;
    require Search::Tools::QueryParser;
    return Search::Tools::QueryParser->new(@_);
}

sub regexp {
    my $class = shift;

    warnings::warn(
        "as of version 0.24 you should use parser() instead of regexp()")
        if warnings::enabled();
        
    my %extra = @_;
    my $q = delete( $extra{query} ) || croak "query required";
    return $class->parser(%extra)->parse($q);
}

sub hiliter {
    my $class = shift;
    require Search::Tools::HiLiter;
    return Search::Tools::HiLiter->new(@_);
}

sub snipper {
    my $class = shift;
    require Search::Tools::Snipper;
    return Search::Tools::Snipper->new(@_);
}

sub transliterate {
    my $class = shift;
    require Search::Tools::Transliterate;
    return Search::Tools::Transliterate->new->convert(@_);
}

sub spellcheck {
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
 
 my $string     = 'the quik brown fox';
 my $qparser    = Search::Tools->parser();
 my $query      = $qparser->parse($string);
 my $snipper    = Search::Tools->snipper(query => $query);
 my $hiliter    = Search::Tools->hiliter(query => $query);
 my $spellcheck = Search::Tools->spellcheck(query_parser => $qparser);

 my $suggestions = $spellcheck->suggest($string);
 
 for my $s (@$suggestions) {
    if (! $s->{suggestions}) {
        # $s->{word} was spelled correctly
    }
    elsif (@{ $s->{suggestions} }) {
        printf "Did you mean: %s\n", join(' or ', @{$s->{suggestions}}));
    }
 }

 for my $result (@search_results) {
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

Perl 5.8.3 or later is required. This is for full UTF-8 support.

The following CPAN modules are required:

=over

=item Rose::Object

=item Search::QueryParser

=item Data::Dump

=item File::Slurp

=item Encode

=item Carp

=back

The following CPAN modules are recommended for the full set of features
and for performance.

=over

=item Text::Aspell

=item Class::XSAccessor

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

=head1 EXAMPLES

See the tests in t/ and the example scripts in example/.
 
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
