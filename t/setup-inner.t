#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';

my $CLASS = 'Test::WSOF';

require_ok($CLASS);

ok($CLASS->isa('App::Cmd'), "$CLASS subclasses App::Cmd");

my $app = $CLASS->new;

is_deeply(
  [ sort $app->command_names ],
  [ sort qw(help --help -h --version -? commands poot version) ],
  "got correct list of registered command names",
);

is_deeply(
  [ sort $app->command_plugins ],
  [ qw(
    App::Cmd::Command::commands
    App::Cmd::Command::help
    App::Cmd::Command::version
    Test::WSOF::Command::poot
  ) ],
  "got correct list of registered command plugins",
);

{
  local @ARGV = qw(poot);
  my $return = eval { $app->run };

  is($return, 'woof woof poot', "inner package commands work with Setup");
}

