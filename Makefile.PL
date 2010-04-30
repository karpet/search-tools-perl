use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.008003;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'Search::Tools',
    VERSION_FROM  => 'lib/Search/Tools.pm',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/Tools.pm',
    ABSTRACT_FROM => 'lib/Search/Tools.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Search::Query'      => '0.14',
        'Encode'             => '0',
        'Rose::ObjectX::CAF' => '0.03',
        'Data::Dump'         => 0,
        'File::Slurp'        => 0,
        'Test::More'         => 0.94,
        'Encoding::FixLatin' => 0,

        #'Text::Aspell'          => '0.06',  # optional

    },
    H => [qw( search-tools.c search-tools.h )],

    #CCFLAGS => '-Wall -pg', # gcc opt only
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Search-Tools-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'http://perl.peknet.com/wiki/SearchTools',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools',
                    repository => 'http://svn.peknet.com/perl/Search-Tools',
                },
            }
            )
    ),

);
