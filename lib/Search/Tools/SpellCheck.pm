package Search::Tools::SpellCheck;

use 5.008_003;
use strict;
use warnings;

use Carp;
use base qw( Class::Accessor::Fast );
use Text::Aspell;

our $VERSION = '0.14';

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless($self, $class);
    $self->_init(@_);
    return $self;
}

sub _init
{
    my $self  = shift;
    my %extra = @_;
    @$self{keys %extra} = values %extra;

    $self->{max_suggest} ||= 4;

    $self->mk_accessors(
        qw(
          max_suggest
          dict
          aspell
          kw
          query
          )
    );
    
    if ($self->query)
    {
        unless ($self->query->isa('Search::Tools::RegExp::Keywords'))
        {
            croak "query must be a S::T::RegExp::Keywords object";
        }
        $self->kw( $self->query->kw );
    }

    unless ($self->kw && $self->kw->isa('Search::Tools::Keywords'))
    {
        croak "S::T::Keywords object required";
    }

    $self->aspell(Text::Aspell->new or croak "can't get new() Text::Aspell");

    $self->aspell->set_option('lang', $self->kw->lang);
    $self->_check_err;
    $self->aspell->set_option('sug-mode', 'fast');
    $self->_check_err;
    $self->aspell->set_option('master', $self->dict) if $self->dict;
    $self->_check_err;

}

sub _check_err
{
    my $self = shift;
    carp $self->aspell->errstr if $self->aspell->errstr;
}

sub suggest
{
    my $self    = shift;
    my $query   = shift or croak "query required";
    my $suggest = [];
    my $phr_del = $self->kw->phrase_delim;

    for my $k ($self->kw->extract($query))
    {

        $k =~ s/$phr_del//g;
        my @w = split(m/\ +/, $k);

      WORD: for my $word (@w)
        {

            my $s = {word => $word};
            if ($self->aspell->check($word))
            {
                $self->_check_err;
                $s->{suggestions} = 0;
            }
            else
            {
                my @sg = $self->aspell->suggest($word);
                $self->_check_err;
                if (!@sg or !defined $sg[0])
                {
                    $s->{suggestions} = [];
                }
                else
                {

                    if ($self->kw->ignore_case)
                    {

                        # make them unique but preserve order
                        my $c = 0;
                        my %u = map { lc($_) => $c++ } @sg;
                        @sg = sort { $u{$a} <=> $u{$b} } keys %u;
                    }

                    $s->{suggestions} = [splice(@sg, 0, $self->max_suggest)];
                }
            }
            push(@$suggest, $s);

        }
    }

    return $suggest;
}

1;

__END__


=head1 NAME

Search::Tools::SpellCheck - offer spelling suggestions

=head1 SYNOPSIS

 use Search::Tools::Keywords;
 use Search::Tools::SpellCheck;
 
 my $query = 'the quick fox color:brown and "lazy dog" not jumped';
 
 my $kw = 
    Search::Tools::Keywords->new;
 
 my $spellcheck = 
    Search::Tools::SpellCheck->new(
                        dict        => 'path/to/my/dictionary',
                        max_suggest => 4,
                        kw          => $kw
                        
                        );
                        
 my $suggestions = $spellcheck->suggest($query);
 
 
=head1 DESCRIPTION

This module offers suggestions for alternate spellings using Text::Aspell.

=head1 METHODS

=head2 new( %I<opts> )

Create a new SpellCheck object.
%I<opts> should include:

=over

=item dict

Path(s) to your dictionary.

=item lang

Language to use. Default is C<en_US>.

=item max_suggest

Maximum number of suggested spellings to return. Default is C<4>.

=back

=head2 suggest( @I<keywords> )

Returns an arrayref of hashrefs. Each hashref is composed of the following
key/value pairs:

=over

=item word

The keyword used.

=item suggestions

If value is C<0> (zero) then the word was found in the dictionary
and is spelling correctly.

If value is an arrayref, the array contains a list of suggested spellings.

=back

=head2 aspell

If you need access to the Text::Aspell object used internally,
this accessor will get/set it.

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of this module.

Thanks to Bill Moseley, Text::Aspell maintainer, for the API
suggestions for this module.

=head1 COPYRIGHT

Copyright 2006 by Peter Karman. 
This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools::Keywords, Text::Aspell
