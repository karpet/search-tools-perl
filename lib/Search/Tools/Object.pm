package Search::Tools::Object;
use strict;
use warnings;
use Carp;
use base qw( Rose::Object );
use Search::Tools::MethodMaker;

our $VERSION = '0.24';

__PACKAGE__->mk_accessors( __PACKAGE__->common_methods );

=pod

=head1 NAME

Search::Tools::Object - base class for Search::Tools objects

=head1 METHODS

=cut

sub _init {
    croak "use init() instead";
}

sub init {
    my $self = shift;
    while (@_) {
        my $method = shift;
        $self->{$method} = shift;
    }
    $self->{debug} ||= $ENV{PERL_DEBUG} || 0;
    return $self;
}

# backcompat for CAF
sub mk_accessors {
    my $class = shift;
    Search::Tools::MethodMaker->make_methods( { target_class => $class },
        scalar => \@_ );
}

sub mk_ro_accessors {
    my $class = shift;
    Search::Tools::MethodMaker->make_methods( { target_class => $class },
        'scalar --ro' => \@_ );
}

sub common_methods {
    return qw(
        debug
        locale
        charset
        lang
        stopwords
        wildcard
        token_re
        word_characters
        ignore_first_char
        ignore_last_char
        stemmer
        phrase_delim
        ignore_case
    );
}

1;

__END__

=head1 COMMON ACCESSORS

The following common accessors are inherited by every module in Search::Tools:

    stopwords
    wildcard
    token_re
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

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

=head1 COPYRIGHT

Copyright 2007 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools

=cut
