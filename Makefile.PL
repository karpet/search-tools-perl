use ExtUtils::MakeMaker;
use 5.008_003;

WriteMakefile(
    NAME         => 'Search::Tools',
    VERSION_FROM => 'lib/Search/Tools.pm',
    PREREQ_PM    => {
        'Search::QueryParser' => '0',
        'Encode'              => '0',
        'Rose::Object'        => '0',
        'Data::Dump'          => 0,
        'File::Slurp'         => 0,

        #'Text::Aspell'          => '0.06',  # optional

    },
    (   $] >= 5.005
        ? ( ABSTRACT_FROM => 'lib/Search/Tools.pm',
            AUTHOR        => ' Peter Karman <perl@peknet.com>'
            )
        : ()
    ),
);
