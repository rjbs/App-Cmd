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

  local $@;
  eval { print $self->app->_usage_text . "\n" };

  print "Available commands:\n\n";

  my @primary_commands =
    map { ($_->command_names)[0] } 
    $self->app->command_plugins;

  my @cmd_groups = $self->sort_commands( @primary_commands );

  my $fmt_width = 0;
  for (@primary_commands) { $fmt_width = length if length > $fmt_width }
  $fmt_width += 2; # pretty

  foreach my $cmd_set ( @cmd_groups ) {
    for my $command (@$cmd_set) {
      my $abstract = $self->app->plugin_for($command)->abstract;
      printf "%${fmt_width}s: %s\n", $command, $abstract;
    }
    print "\n";
  }
}

=head2 C<sort_commands>

  my @sorted = $cmd->sort_commands( @unsorted );

Orders the list of commands so that 'help' and 'commands' show up at the top.

=cut

sub sort_commands {
  my ( $self, @commands ) = @_;

  my $float = qr/^(?:help|commands)$/;

  my @head = sort grep { $_ =~ $float } @commands;
  my @tail = sort grep { $_ !~ $float } @commands;

  return ( \@head, \@tail );
}

1;
