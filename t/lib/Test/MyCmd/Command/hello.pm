package Test::MyCmd::Command::hello;

use strict;
use warnings;

use base qw(App::Cmd::Command);

use IPC::Cmd qw/can_run/;

sub execute {
  my ($self, $opt, $arg) =@_;

  my $echo = can_run("echo");
  $self->usage_error("Program 'echo' not found") unless $echo;
  system($echo, "Hello World");
  return;
}

1;
