#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use lib 't/lib';

use Test::MyCmd;

my $cmd = Test::MyCmd->new;

isa_ok($cmd, 'Test::MyCmd');

is_deeply(
  [ sort $cmd->command_names ],
  [ qw(commands frob frobulate justusage stock) ],
  "got correct list of registered command names",
);

is_deeply(
  [ sort $cmd->command_plugins ],
  [ qw(
    App::Cmd::Command::commands
    Test::MyCmd::Command::frobulate
    Test::MyCmd::Command::justusage
    Test::MyCmd::Command::stock
  ) ],
  "got correct list of registered command plugins",
);

{
  local @ARGV = qw(frob --widget wname your fat face);
  eval { $cmd->run };
  
  is(
    $@,
    "the widget name is wname - your fat face\n",
    "command died with the correct string",
  );
}

{
  local $0 = "mycmd";
  local @ARGV = qw(justusage);
  eval { $cmd->run };

  my $error = $@;
  
  like(
    $error,
    qr/^mycmd justusage/,
    "default usage_desc is okay",
  );
}

{
  local @ARGV = qw(stock);
  eval { $cmd->run };
  
  like($@, qr/mandatory method/, "un-subclassed &run leads to death");
}

SKIP: {
  my $have_TO = eval { require Test::Output; 1; };
  print $@;
  skip "these tests require Test::Output", 4 unless $have_TO;

  local @ARGV = qw(commands);

  my ($output) = Test::Output::output_from(sub { $cmd->run });

  for my $name (qw(commands frobulate justusage stock)) {
    like($output, qr/^\s+\Q$name\E/sm, "$name plugin in listing");
  }
}
