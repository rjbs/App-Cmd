#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';

my $CLASS = 'Test::WithSetup';

require_ok($CLASS);

ok($CLASS->isa('App::Cmd'), "$CLASS subclasses App::Cmd");

my $app = $CLASS->new;

is_deeply(
  [ sort $app->command_names ],
  [ sort qw(help --help -h -? commands alfie) ],
  "got correct list of registered command names",
);

