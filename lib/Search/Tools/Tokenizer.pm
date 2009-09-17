package Search::Tools::Tokenizer;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Search::Tools;    # XS package required
use Search::Tools::Token;
use Search::Tools::TokenList;
use Search::Tools::UTF8;
use Carp;

our $VERSION = '0.24';

__PACKAGE__->mk_accessors(qw( re ));

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->{re} ||= qr/\w+(?:'\w+)*/;
    if ( $self->debug ) {
        $self->set_debug( $self->debug - 1 );    # XS debug a level higher
    }
    return $self;
}

sub tokenize_pp {
    require Search::Tools::TokenPP;
    require Search::Tools::TokenListPP;

    my $self = shift;
    if ( !defined $_[0] ) {
        croak "str required";
    }

    # XS modifies the original arg, so we do too.
    # this is same slight optimization XS does. ~5%
    if ( !is_ascii( $_[0] ) ) {
        $_[0] = to_utf8( $_[0] );
    }
    my $heat_seeker = $_[1];

    # match_num ($_[2]) not supported in PP

    my @tokens = ();
    my $i      = 0;
    my $re     = $self->{re};
    for ( split( m/($re)/, $_[0] ) ) {
        next unless length($_);
        my $tok = bless(
            {   'pos'    => $i++,
                str      => $_,
                is_hot   => 0,
                is_match => 0,
                len      => bytes::length($_),
                u8len    => length($_),
            },
            'Search::Tools::TokenPP'
        );
        if ( $_ =~ m/^$re$/ ) {
            $tok->{is_match} = 1;
            $heat_seeker->($tok) if $heat_seeker;
        }
        push @tokens, $tok;
    }
    return bless(
        {   tokens => \@tokens,
            num    => $i,
            'pos'  => 0,
        },
        'Search::Tools::TokenListPP'
    );
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
