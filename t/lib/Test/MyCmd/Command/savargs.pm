package Test::MyCmd::Command::savargs;

use strict;
use warnings;

use parent qw(App::Cmd::Command);

our @LAST_ARGS;

sub execute {
  my ($self, $opt, $arg) =@_;

  @LAST_ARGS = @$arg;

  return;
}

1;
