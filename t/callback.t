#!perl
use strict;
use warnings;

use Test::More 'no_plan';
use App::Cmd::Tester;

use lib 't/lib';

my $CLASS = 'Test::WithCallback';

require_ok($CLASS);

ok($CLASS->isa('App::Cmd'), "$CLASS subclasses App::Cmd");

my $app = $CLASS->new;

is_deeply(
  [ sort $app->command_names ],
  [ sort qw(help --help -h --version -? commands lol version) ],
  "got correct list of registered command names",
);

my $return = test_app('Test::WithCallback', [ qw(lol -e 2) ]);
is($return->stdout, 'yay', "Callback validated correctly");

$return = test_app('Test::WithCallback', [ qw(lol -e 1) ]);
like(
  $return->error,
  qr/even.+valid.email/,
  "Failing Params::Validate callback prints nice error message"
);
