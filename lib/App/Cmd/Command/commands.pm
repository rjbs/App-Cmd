package App::Cmd::Command::commands;

=head1 NAME

App::Cmd::Command::commands - list the application's commands

=head1 VERSION

 $Id$

=head1 DESCRIPTION

This command plugin implements a "commands" command.  This command will list
all of an App::Cmd's commands and their abstracts.

=cut

use strict;
use warnings;

use base qw(App::Cmd::Command);

sub run {
  my ($self) = @_;

  my @primary_commands =
    map { my ($n) = $_->command_names; $n } 
    $self->app->command_plugins;

  for my $command (sort @primary_commands) {
    my $abstract = $self->app->plugin_for($command)->abstract;
    printf "%10s: %s\n", $command, $abstract;
  }
}

1;
