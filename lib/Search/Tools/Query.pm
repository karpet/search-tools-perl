package Search::Tools::Query;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub {1},
    fallback => 1;
use Carp;

#use Data::Dump qw( dump );

our $VERSION = '0.24';

__PACKAGE__->mk_ro_accessors(
    qw(
        keywords
        parser
        str
        regex
        )
);

sub tree {
    my $self = shift;
    my $q    = $self->str;
    return $self->parser->parse( $q, 1 );
}

sub str_clean {
    my $self = shift;
    my $tree = $self->tree;
    return $self->parser->unparse($tree);
}

sub regexp_for {
    my $self    = shift;
    my $keyword = shift;
    unless ( defined $keyword ) {
        croak "keyword required";
    }
    return $self->regex->re($keyword);
}

*regex_for = \&regexp_for;

1;

__END__

=head1 NAME

Search::Tools::Query - objectified string for highlighting, snipping, etc.

=head1 SYNOPSIS

 use Search::Tools::QueryParser;
 my $qparser = Search::Tools::QueryParser->new;
 my $query    = $qparser->parse(q(the quick color:brown "fox jumped"));
 my $keywords = $query->keywords; # ['quick', 'brown', '"fox jumped"']
 my $regexp   = $query->regexp_for($keywords->[0]); # S::T::R::Keyword
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
