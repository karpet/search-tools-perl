use strict;
use Test::More tests => 11;
use Data::Dump qw( dump );
use File::Slurp;

BEGIN { use_ok('Search::Tools::Snipper') }

sub token_snipper {

    #warn dump(\@_);
    my $self   = shift;
    my $qre    = $self->{_qre};
    my $window = $self->{context};

    #warn $self->tokenizer->re;
    #warn $qre;
    my $tokens = $self->tokenizer->tokenize(
        $_[0],
        sub {
            if ( $_[0] =~ /$qre/ ) {

                #warn "---------- HOT MATCH $_[0] [$qre] --------";
                $_[0]->set_hot(1);
            }

            # TODO phrase match
        }
    );

    # build heatmap
    my @heatmap;
    my @snips;
    my $max_index  = $tokens->len - 1;
    my $tokens_arr = $tokens->as_array;
    while ( my $tok = $tokens->next ) {
        if ( $tok->is_hot ) {

            # get window
            my $pos = $tok->pos;
            my ( $start, $end );
            if ( $pos > $window ) {
                $start = $pos - $window;
            }
            if ( $pos < ( $max_index - $window ) ) {
                $end = $pos + $window;
            }
            $start ||= 0;
            $end   ||= $max_index;
            push( @snips,
                join( '', map {"$_"} @$tokens_arr[ $start .. $end ] ) );
            push( @heatmap, $tok->pos );
        }
    }

    # naive.
    # TODO check overlap
    #warn "heatmap: " . dump \@heatmap;
    #warn "snips: " . dump \@snips;
    if (@snips) {
        my $occur_index = $self->occur - 1;
        @snips = @snips[ 0 .. $occur_index ];
        return ' ... ' . join( ' ... ', @snips ) . ' ... ';
    }
    else {
        return $self->_dump_snip( $_[0] );
    }

}

my $text = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
EOF

my @q = ( 'squiggle', 'type', 'course', '"human events"' );

ok( my $s = Search::Tools::Snipper->new(
        query     => [@q],
        max_chars => length($text) - 1,
        snipper   => \&token_snipper,
    ),
    "snipper"
);

ok( my $snip = $s->snip($text), "snip" );

diag($snip);

ok( length($snip) < $s->max_chars, "max_chars" );

#diag($s->type_used);

$text = read_file('t/docs/test.txt');

@q = qw(intramuralism maimedly sculpt);

ok( $s = Search::Tools::Snipper->new(
        query     => [@q],
        max_chars => length($text) - 1,
        snipper   => \&token_snipper,
    ),
    "new snipper"
);

ok( $snip = $s->snip($text), "new snip" );

#diag($snip);
diag( $s->type_used );

ok( length($snip) < $s->max_chars, "more snip" );

# test context
my $text2 = <<EOF;
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
when in the course of human events
you need to create a test to prove that
your code isn't just a silly mishmash
of squiggle this and squiggle that,
type man! type! until you've reached
enough words to justify your paltry existence.
amen.
EOF

my $excerpt
    = qq{type man! type! until you've reached enough words to justify your paltry existence. amen. when in the course of human events you need to create a test};

my $regex = Search::Tools->regexp( query => 'amen' );
my $snip_excerpt = Search::Tools::Snipper->new(
    query   => $regex,
    occur   => 1,
    context => 26,
    snipper => \&token_snipper,
);
my $snip_title = Search::Tools::Snipper->new(
    query   => $regex,
    occur   => 1,
    context => 8,
    snipper => \&token_snipper,
);

like( $snip_excerpt->snip($text2), qr/$excerpt/, "excerpt context" );
ok( $snip_excerpt->type('re'), "set re type" );
like( $snip_excerpt->snip($text2), qr/$excerpt/,
    "re matches loop algorithm" );
diag( $snip_excerpt->type_used );

is( $snip_title->snip($text2),
    qq{ ... justify your paltry existence. amen. when in the course ... },
    "8 context"
);
diag( $snip_title->type_used );
