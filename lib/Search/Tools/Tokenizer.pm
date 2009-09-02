package Search::Tools::Tokenizer;
use strict;
use warnings;
use base qw( Search::Tools::Object );
use Search::Tools;    # XS package required
use Search::Tools::Token;
use Search::Tools::TokenPP;
use Search::Tools::TokenList;
use Search::Tools::TokenListPP;
use Search::Tools::UTF8;
use Carp;

our $VERSION = '0.24';

__PACKAGE__->mk_accessors(qw( re ));

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->{re} ||= qr/\w+(?:'\w+)*/;
    $self->set_debug( $self->debug );
    return $self;
}

sub tokenize_pp {
    my $self = shift;
    if ( !defined $_[0] ) {
        croak "str required";
    }

    # xs modifies the original arg, so we do too.
    $_[0] = to_utf8( $_[0] );
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
