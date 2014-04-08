package Search::Tools::ArgNormalizer;
use Moo::Role;
use Carp;
use Scalar::Util qw( blessed );
use Data::Dump qw( dump );

sub BUILDARGS {
    my $self  = shift;
    my %args  = @_;
    my $q     = delete $args{query};
    my $debug = delete $args{debug};
    if ( !defined $q ) {
        confess "query required";
    }
    if ( !ref($q) ) {
        require Search::Tools::QueryParser;
        $args{query} = Search::Tools::QueryParser->new(
            debug => $debug,
            map { $_ => delete $args{$_} }
                grep { $self->queryparser_can($_) } keys %args
        )->parse($q);
    }
    elsif ( ref($q) eq 'ARRAY' ) {
        carp "query ARRAY ref deprecated as of version 0.24";
        require Search::Tools::QueryParser;
        $args{query} = Search::Tools::QueryParser->new(
            debug => $debug,
            map { $_ => delete $args{$_} }
                grep { $self->queryparser_can($_) } keys %args
        )->parse( join( ' ', @$q ) );
    }
    elsif ( blessed($q) and $q->isa('Search::Tools::Query') ) {
        $args{query} = $q;
    }
    else {
        confess
            "query param required to be a scalar string or Search::Tools::Query object";
    }
    $args{debug} = $debug;    # restore so it can be passed on
                              #dump \%args;
    return \%args;
}

sub queryparser_can {
    my $self = shift;
    my $attr = shift or confess "attr required";
    my $can  = Search::Tools::QueryParser->can($attr);

   #warn
   #    sprintf( "QueryParser->can(%s)==%s\n", $attr, ( $can || '[undef]' ) );

    return $can;
}

1;
