#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for author testing');
  }
}

use Test::More;

eval "use Test::PureASCII";
if ( $@ ) {
  plan skip_all => 'Test::PureASCII required for testing POD';
}
else {
  all_perl_files_are_pure_ascii();
}


