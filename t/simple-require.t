#!perl
use strict;
use warnings;

use Test::More tests => 1;
use App::Cmd::Tester;

use lib 't/lib';

require Test::MySimple;

my $return = test_app(Test::MySimple->import, [ qw(bite the wax tadpole) ]);

# Horrible hack. -- rjbs, 2009-06-27
my $stdout = $return->stdout;
my $struct = eval $stdout;

is_deeply(
  $struct,
  [ { }, [ qw(bite the wax tadpole) ] ],
  "our simple app runs properly",
);
