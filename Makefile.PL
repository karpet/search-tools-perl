use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.008003;

WriteMakefile(
    NAME          => 'Search::Tools',
    VERSION_FROM  => 'lib/Search/Tools.pm',
    LICENSE       => 'perl',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Search/Tools.pm',
    ABSTRACT_FROM => 'lib/Search/Tools.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Search::QueryParser' => '0',
        'Encode'              => '0',
        'Rose::Object'        => '0',
        'Data::Dump'          => 0,
        'File::Slurp'         => 0,

        #'Text::Aspell'          => '0.06',  # optional

    },
    H    => [qw( search-tools.h )],
    C    => [qw( search-tools.c )],
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Search-Tools-*' },

);
