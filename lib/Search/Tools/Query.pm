package Search::Tools::Query;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub {1},
    fallback => 1;
use Carp;
use Data::Dump qw( dump );
use Search::Tools::RegEx;

our $VERSION = '0.27';

__PACKAGE__->mk_ro_accessors(
    qw(
        terms
        search_queryparser
        str
        regex
        qp
        )
);

=head1 NAME

Search::Tools::Query - objectified string for highlighting, snipping, etc.

=head1 SYNOPSIS

 use Search::Tools::QueryParser;
 my $qparser  = Search::Tools::QueryParser->new;
 my $query    = $qparser->parse(q(the quick color:brown "fox jumped"));
 my $terms    = $query->terms; # ['quick', 'brown', '"fox jumped"']
 my $regex    = $query->regex_for($terms->[0]); # S::T::RegEx
 my $tree     = $query->tree; # the Search::QueryParser-parsed struct
 print "$query\n";  # the quick color:brown "fox jumped"
 print $query->str . "\n"; # same thing


=head1 DESCRIPTION


=head1 METHODS

=head2 terms

Array ref of key words from the original query string.
See Search::Tools::QueryParser for controls over ignore_fields()
and tokenizing regex.

B<NOTE:>
Only positive words are extracted by QueryParser. 
In other words, if you search for:

 foo not bar
 
then only C<foo> is returned. Likewise:

 +foo -bar
 
would return only C<foo>.

=head2 search_queryparser

The Search::QueryParser object used to parse the original string.

=head2 str

The original string.

=head2 regex

The hash ref of terms to Search::Tools::RegEx objects.

=head2 qp

The Search::Tools::QueryParser object used to generate the Query.

=head2 from_regexp_keywords( I<RegExp_Keywords_object> )

Class method for easing backwards compatability with the pre-0.24 API.

=cut

# backcompat
sub from_regexp_keywords {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $rekw  = shift or croak "RegExp::Keywords required";

    #dump $rekw;

    my $regex = {};
    for ( $rekw->keywords ) {
        my $rek = $rekw->{hash}->{$_} or croak "no Keyword object for $_";
        $regex->{$_} = Search::Tools::RegEx->new(
            plain     => $rek->plain,
            html      => $rek->html,
            is_phrase => $rek->phrase,
            term      => $rek->word,
        );
    }
    my $self = $class->new(
        terms              => $rekw->{array},
        regex              => $regex,
        str                => $rekw->{kw}->{query},
        search_queryparser => $rekw->{kw}->{parser},
        qp                 => $rekw->{kw},
    );
    return $self;
}

=head2 num_terms

Returns the number of terms().

=cut

sub num_terms {
    return scalar @{ shift->{terms} };
}

=head2 tree

Returns the Search::QueryParser->parse() of the original query str().

=cut

sub tree {
    my $self = shift;
    my $q    = $self->str;
    return $self->search_queryparser->parse( $q, 1 );
}

=head2 str_clean

Returns the Search::QueryParser->unparse() of tree().

=cut

sub str_clean {
    my $self = shift;
    my $tree = $self->tree;
    return $self->search_queryparser->unparse($tree);
}

=head2 regex_for(I<term>)

Returns a Search::Tools::RegEx object for I<term>.

=cut

sub regex_for {
    my $self = shift;
    my $term = shift;
    unless ( defined $term ) {
        croak "term required";
    }
    if ( !exists $self->{regex} or !exists $self->{regex}->{$term} ) {
        croak "no regex for $term";
    }
    return $self->{regex}->{$term};
}

=head2 regexp_for

Alias for regex_for(). The author has come to prefer "regex"
instead of "regexp" because it's one less keystroke.

=cut

*regexp_for = \&regex_for;

=head2 terms_as_regex

Returns all terms() as a single qr// regex, pipe-joined in a "OR"
logic.

=cut

sub terms_as_regex {
    my $self     = shift;
    my $wildcard = $self->qp->wildcard;
    my $wild_esc = quotemeta($wildcard);
    my $wc       = $self->qp->word_characters;
    my @re;
    for my $term ( @{ $self->{terms} } ) {

        my $q = quotemeta($term);    # quotemeta speeds up the match, too
                                     # even though we have to unquote below

        $q =~ s/\\$wild_esc/[$wc]*/; # wildcard match is very approximate

        # treat phrases like OR'd words
        # since that will just create more matches.
        # if hiliting later, the phrase will be treated as such.
        $q =~ s/(\\ )+/\|/g;

        push( @re, $q );
    }

    my $j = sprintf( '(%s)', join( '|', @re ) );
    return qr/$j/i;
}

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

Search::QueryParser
