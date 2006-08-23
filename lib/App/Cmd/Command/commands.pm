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
    map { ($_->command_names)[0] } 
    $self->app->command_plugins;

  @primary_commands = $self->sort_commands( @primary_commands );

  for my $command (@primary_commands) {
    my $abstract = $self->app->plugin_for($command)->abstract;
    printf "%10s: %s\n", $command, $abstract;
  }
}

sub sort_commands {
  my ( $self, @commands ) = @_;

  my $float = qr/^(?:help|commands)$/;

  sort {
    -1*$a =~ $float
    || $b =~ $float
    || $a cmp $b;
  } @commands;
}

1;
