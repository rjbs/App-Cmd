#!perl

use strict;
use warnings;

use Test::More tests => 13;
use App::Cmd::Tester;

use lib 't/lib';

use Test::MyCmd;

my $app = Test::MyCmd->new;

isa_ok($app, 'Test::MyCmd');

is_deeply(
  [ sort $app->command_names ],
  [ sort qw(help --help -h -? commands exit frob frobulate hello justusage stock) ],
  "got correct list of registered command names",
);

is_deeply(
  [ sort $app->command_plugins ],
  [ qw(
    App::Cmd::Command::commands
    App::Cmd::Command::help
    Test::MyCmd::Command::exit
    Test::MyCmd::Command::frobulate
    Test::MyCmd::Command::hello
    Test::MyCmd::Command::justusage
    Test::MyCmd::Command::stock
  ) ],
  "got correct list of registered command plugins",
);

{
  local @ARGV = qw(frob --widget wname your fat face);
  eval { $app->run };

  is(
    $@,
    "the widget name is wname - your fat face\n",
    "command died with the correct string",
  );
}

{
  local @ARGV = qw(justusage);
  eval { $app->run };

  my $error = $@;

  like(
    $error,
    qr/^basic.t justusage/,
    "default usage_desc is okay",
  );
}

{
  local @ARGV = qw(stock);
  eval { $app->run };

  like($@, qr/mandatory method/, "un-subclassed &run leads to death");
}

my $return = test_app('Test::MyCmd', [ qw(commands) ]);

for my $name (qw(commands frobulate hello justusage stock)) {
  like($return->stdout, qr/^\s+\Q$name\E/sm, "$name plugin in listing");
}

{
  my $return = test_app('Test::MyCmd', [ qw(exit 1) ]);
  is($return->exit_code, 1, "exit code is 1");
}

{
  my $return = test_app('Test::MyCmd', [ qw(unknown) ]);
  is($return->exit_code, 1, "exit code is 1");
}
