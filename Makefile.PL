use ExtUtils::MakeMaker;
use 5.8.3;

WriteMakefile(
    NAME         => 'Search::Tools',
    VERSION_FROM => 'lib/Search/Tools.pm',
    PREREQ_PM    => {
        'Search::QueryParser'   => '0.1',
        'Encode'                => '0.1',
        'Class::Accessor::Fast' => '0.1',
        'Text::Aspell'          => '0.06',
        'Data::Dump'            => 0,

                 },
    (
     $] >= 5.005
     ? (
        ABSTRACT_FROM => 'lib/Search/Tools.pm',
        AUTHOR        => ' Peter Karman <perl@peknet.com>'
       )
     : ()
    ),
);
