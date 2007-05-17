package Search::Tools::UTF8;
use strict;
use warnings;
use Carp;
use Search::Tools;    # XS stuff
use Encode;
use charnames ':full';
use base qw( Exporter );
our @EXPORT = qw(   to_utf8 is_valid_utf8 is_flagged_utf8
  is_ascii is_latin1 is_sane_utf8
  find_bad_utf8

  );
our $Debug = 0;

our $VERSION = '0.01';

sub to_utf8
{
    my $str = shift;
    my $charset = shift || 'iso-8859-1';

    # checks first
    if (is_flagged_utf8($str))
    {
        return $str;
    }
    if (is_valid_utf8($str))
    {
        Encode::_utf8_on($str);
        return $str;
    }
    if (is_ascii($str))
    {
        Encode::_utf8_on($str);
        return $str;
    }

    $Debug
      and carp "converting $str from $charset -> utf8";
    my $c = Encode::decode($charset, $str);
    $Debug and carp "converted $c";

    unless (is_sane_utf8($c))
    {
        carp "not sane: $c";
    }

    return $c;
}

sub is_flagged_utf8
{
    return Encode::is_utf8($_[0]);
}

my $re_bit = join "|", map { Encode::encode("utf8", chr($_)) } (127 .. 255);

#binmode STDERR, ":utf8";
#print STDERR $re_bit;

sub is_sane_utf8
{
    my $string = shift;
    my $warnings = shift || 0;

    while ($string =~ /($re_bit)/o)
    {

        # work out what the double encoded string was
        my $bytes = $1;

        my $index = $+[0] - length($bytes);
        my $codes = join '', map { sprintf '<%00x>', ord($_) } split //, $bytes;

        # what charecter does that represent?
        my $char = Encode::decode("utf8", $bytes);
        my $ord  = ord($char);
        my $hex  = sprintf '%00x', $ord;
        $char = charnames::viacode($ord);

        # print out diagnostic messages
        if ($warnings)
        {

            warn(qq{Found dodgy chars "$codes" at char $index\n});
            if (Encode::is_utf8($string))
            {
                warn("Chars in utf8 string look like utf8 byte sequence.");
            }
            else
            {
                warn("String not flagged as utf8...was it meant to be?\n");
            }
            warn(
                "Probably originally a $char char - codepoint $ord (dec), $hex (hex)\n"
            );

        }
        return 0;
    }
    1;
}

sub is_latin1
{
    my $string = shift;

    if ($string =~ /([^\x{00}-\x{ff}])/)
    {

        # explain why we failed
        my $dec = ord($1);
        my $hex = sprintf '%x', $dec;

        carp("Char $+[0] not Latin-1 (it's $dec dec / $hex hex)")
          if $Debug;
        return 0;
    }
    1;
}

sub is_ascii
{
    my $buf = shift;
    if ($buf =~ m/([^\x{00}-\x{7f}])/o)
    {

        # explain why we failed
        my $dec = ord($1);
        my $hex = sprintf '%02x', $dec;

        carp("Char $+[0] not ASCII (it's $dec dec / $hex hex)")
          if $Debug;

        return 0;
    }
    1;
}

1;

__END__

=pod

=head1 NAME

Search::Tools::UTF8 - UTF8 string wrangling

=head1 SYNOPSIS

 use Search::Tools::UTF8;
 is_valid_utf8($str);
 find_bad_utf8($str);
 
=head1 DESCRIPTION

Search::Tools::UTF8 supplies common UTF8-related functions.


=head1 FUNCTIONS


=head2 is_valid_utf8( I<text> )

Returns true if I<text> is a valid sequence of UTF-8 bytes,
regardless of how Perl has it flagged (is_utf8 or not).

=head2 is_ascii( I<text> )

If I<text> contains no bytes above 127, then returns true (1). Otherwise,
returns false (0). Used by convert() internally to check I<text> prior
to transliterating.

=head2 is_latin1( I<text> )

Returns true if I<text> lies within the Latin1 charset.

=head2 is_flagged_utf8( I<text> )

Returns true if Perl thinks I<text> is UTF-8. Same as Encode::is_utf8().

=head2 is_sane_utf8( I<text> )

Will test for double-y encoded I<text>. Returns true if I<text> looks ok.
See Text::utf8 docs for explanation.

=head2 find_bad_utf8( I<text> )

Returns string of bad bytes from I<text>. This of course assumes that I<text>
is not valid UTF-8, so use it like:

 croak "bad bytes: " . find_bad_utf8($str) 
    unless is_valid_utf8($str);

=head2 to_utf8( I<text>, I<charset> )

Shorthand for running I<text> through appropriate is_*() checks and then
converting to UTF-8 if necessary. Returns I<text>  encoded and flagged as UTF-8.

Returns undef if for some reason the encoding failed or the result did not pass
is_sane_utf8().

=head1 BUGS

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of this module.

Many of the UTF-8 tests come directly from Test::utf8.

=head1 COPYRIGHT

Copyright 2007 by Peter Karman. 
This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools, Encode, Test::utf8

=cut
