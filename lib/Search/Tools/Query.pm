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

our $VERSION = '0.24';

__PACKAGE__->mk_ro_accessors(
    qw(
        terms
        search_queryparser
        str
        regex
        qp
        )
);

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

sub num_terms {
    return scalar @{ shift->{terms} };
}

sub tree {
    my $self = shift;
    my $q    = $self->str;
    return $self->search_queryparser->parse( $q, 1 );
}

sub str_clean {
    my $self = shift;
    my $tree = $self->tree;
    return $self->search_queryparser->unparse($tree);
}

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

*regexp_for = \&regex_for;

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


Only positive words are extracted. In other words, if you search for:

 foo not bar
 
then only C<foo> is returned. Likewise:

 +foo -bar
 
would return only C<foo>.

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

Search::QueryParser

=cut
