package Search::Tools::RegExp;
use strict;
use warnings::register;
use base qw( Search::Tools::Object );
use Carp;
use Search::Tools::Keywords;
use Search::Tools::RegExp::Keywords;
use Search::Tools::RegExp::Keyword;

our $VERSION = '0.34';

__PACKAGE__->mk_accessors(qw( kw ));

sub init {
    my $self         = shift;
    my %args         = @_;
    my @args_to_init = grep { $self->can($_) } keys %args;
    my @args_to_pass = grep { !$self->can($_) } keys %args;

    $self->SUPER::init( map { $_ => $args{$_} } @args_to_init );

    $self->kw(
        Search::Tools::Keywords->new( map { $_ => $args{$_} } @args_to_pass )
    ) unless $self->kw;

}

sub isHTML { croak "use XML->looks_like_html instead of RegExp->isHTML" }

sub build {
    my $self = shift;
    my $query = shift or croak "need query to build() RegExp object";

    warnings::warn(
        "as of version 0.24 you should use Search::Tools::QueryParser instead of RegExp"
    ) if warnings::enabled();

    my $q_array;
    if ( ref $query and ref $query ne 'ARRAY' ) {
        $q_array = $query->{keywords};
    }
    else {
        $q_array = [ $self->kw->extract($query) ];
    }

    my $q2regexp = {};
    for my $q (@$q_array) {
        my ( $plain, $html ) = $self->kw->_build_regex($q);
        $q2regexp->{$q} = Search::Tools::RegExp::Keyword->new(
            plain  => $plain,
            html   => $html,
            word   => $q,
            phrase => $q =~ m/\ / ? 1 : 0
        );

    }

    my $kw = Search::Tools::RegExp::Keywords->new(
        hash        => $q2regexp,
        array       => $q_array,
        kw          => $self->kw,
        start_bound => $self->kw->{start_bound},
        end_bound   => $self->kw->{end_bound},
    );

    return $kw;
}

1;
__END__

=pod

=head1 NAME

Search::Tools::RegExp - (**DEPRECATED**) build regular expressions from search queries

=head1 SYNOPSIS

 # use Search::Tools::QueryParser
 

=head1 DESCRIPTION

As of version 0.24 this class is deprecated in favor of Search::Tools::QueryParser.

=head1 METHODS

=head2 init

=head2 build

=head2 isHTML

=head2 kw

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

HTML::HiLiter, Search::Tools, Search::Tools::RegExp::Keywords, Search::Tools::RegExp::Keyword

=cut
