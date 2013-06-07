#!perl -T

use Test::More;
plan skip_all => "set PERL_AUTHOR_TEST to test POD" unless $ENV{PERL_AUTHOR_TEST};
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();

