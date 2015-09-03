use strict;
use warnings;

package App::Cmd::Command::commands;

use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command' };

# ABSTRACT: list the application's commands

=head1 DESCRIPTION

This command plugin implements a "commands" command.  This command will list
all of an App::Cmd's commands and their abstracts.

=method execute

This is the command's primary method and raison d'etre.  It prints the
application's usage text (if any) followed by a sorted listing of the
application's commands and their abstracts.

The commands are printed in sorted groups (created by C<sort_commands>); each
group is set off by blank lines.

=cut

sub execute {
  my ($self, $opt, $args) = @_;

  my $target = $opt->stderr ? *STDERR : *STDOUT;
 
  my @cmd_groups = $self->app->command_groups;
  my @primary_commands = map { @$_ if ref $_ } @cmd_groups;

  if (!@cmd_groups) {
    @primary_commands =
      grep { $_ ne 'version' }
      map { ($_->command_names)[0] }
      $self->app->command_plugins;

    @cmd_groups = $self->sort_commands(@primary_commands);
  }

  my $fmt_width = 0;
  for (@primary_commands) { $fmt_width = length if length > $fmt_width }
  $fmt_width += 2; # pretty

  foreach my $cmd_set (@cmd_groups) {
    if (!ref $cmd_set) {
      print { $target } "$cmd_set:\n";
      next;
    }
    for my $command (@$cmd_set) {
      my $abstract = $self->app->plugin_for($command)->abstract;
      printf { $target } "%${fmt_width}s: %s\n", $command, $abstract;
    }
    print { $target } "\n";
  }
}

=method C<sort_commands>

  my @sorted = $cmd->sort_commands(@unsorted);

This method orders the list of commands into groups which it returns as a list of
arrayrefs, and optional group header strings.

By default, the first group is for the "help" and "commands" commands, and all
other commands are in the second group.

This method can be overriden by implementing the C<commands_groups> method in
your application base clase.

=cut

sub sort_commands {
  my ($self, @commands) = @_;

  my $float = qr/^(?:help|commands)$/;

  my @head = sort grep { $_ =~ $float } @commands;
  my @tail = sort grep { $_ !~ $float } @commands;

  return (\@head, \@tail);
}

sub opt_spec {
  return (
    [ 'stderr' => 'hidden' ],
  );
}

sub description {
  "This command will list all of commands available and their abstracts.\n";
}


1;
