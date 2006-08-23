package App::Cmd::Command::commands;

=head1 NAME

App::Cmd::Command::commands - list the application's commands

=head1 VERSION

 $Id$

=head1 DESCRIPTION

This command plugin implements a "commands" command.  This command will list
all of an App::Cmd's commands and their abstracts.

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(App::Cmd::Command);

=head2 C<run>

List the app's commands.

=cut

sub run {
  my ($self) = @_;

  my @primary_commands =
    map { ($_->command_names)[0] } 
    $self->app->command_plugins;

  @primary_commands = $self->sort_commands( @primary_commands );

  my $fmt_width = 0;
  for (@primary_commands) { $fmt_width = length if length > $fmt_width }
  $fmt_width += 2; # pretty

  for my $command (@primary_commands) {
    my $abstract = $self->app->plugin_for($command)->abstract;
    printf "%${fmt_width}s: %s\n", $command, $abstract;
  }
}

=head2 C<sort_commands>

  my @sorted = $cmd->sort_commands( @unsorted );

Orders the list of commands so that 'help' and 'commands' show up at the top.

=cut

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
