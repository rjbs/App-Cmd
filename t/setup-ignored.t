use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use lib 't/lib';

is(
  exception {
    require Test::IgnoreCommand;
  },
  undef,
  'Ignored Commands shouldn\'t be fatal'
);

my @plugins = Test::IgnoreCommand->_plugins();

is_deeply( \@plugins, [] , 'no commands were loaded' );

done_testing;
