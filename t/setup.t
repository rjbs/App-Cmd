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
  [ sort qw(help --help -h --version -? commands alfie bertie version) ],
  "got correct list of registered command names",
);

is_deeply(
  [ sort $app->command_plugins ],
  [ qw(
    App::Cmd::Command::commands
    App::Cmd::Command::help
    App::Cmd::Command::version
    Test::WithSetup::Command::alfie
    Test::WithSetup::Command::bertie
  ) ],
  "got correct list of registered command plugins",
);

{
  local @ARGV = qw(alfie);
  my $return = eval { $app->run };

  is_deeply(
    $return,
    {},
    "basically run",
  );
}

{
  local @ARGV = qw(bertie);
  my $return = eval { $app->run };

  is($return->[0], 'Test::XyzzyPlugin', "arg0 = plugin itself");

  isa_ok($return->[1], 'Test::WithSetup::Command');
  isa_ok($return->[1], 'Test::WithSetup::Command::bertie');

  is_deeply(
    $return->[2],
    [ qw(foo bar) ],
    "expected args",
  );
}
