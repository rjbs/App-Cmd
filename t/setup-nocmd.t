#!perl
use strict;
use warnings;

# This should be valid:
#
# package MyApp; use App::Cmd::Setup -app;
# package MyApp::Command::foo; use MyApp -command;
#
# then using MyApp should still load everything under MyApp::Command, even
# though we didn't do:
# package MyApp::Command; use App::Cmd::Setup -command;

use Test::More 'no_plan';

use lib 't/lib';

my $CLASS = 'Test::WSNCC';

require_ok($CLASS);

ok($CLASS->isa('App::Cmd'), "$CLASS subclasses App::Cmd");

my $app = $CLASS->new;

is_deeply(
  [ sort $app->command_names ],
  [ sort qw(help --help -h --version -? commands blort version) ],
  "got correct list of registered command names",
);

is_deeply(
  [ sort $app->command_plugins ],
  [ qw(
    App::Cmd::Command::commands
    App::Cmd::Command::help
    App::Cmd::Command::version
    Test::WSNCC::Command::blort
  ) ],
  "got correct list of registered command plugins",
);

{
  local @ARGV = qw(blort);
  my $return = eval { $app->run };
  
  is_deeply(
    $return,
    {},
    "basically run",
  );
}
