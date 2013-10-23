use strict;
use warnings;

package App::Cmd::Command::version;
use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command'; }

# ABSTRACT: display an app's version

=head1 DESCRIPTION

This plugin implements the C<--version> command. On execution it shows the
program name, it's base class with version number, and the full program name.

=cut

sub command_names { qw/--version/ }

sub execute {
  my ($self, $opts, $args) = @_;

  printf "%s (%s) version %s (%s)\n",
    $self->app->arg0, ref($self->app),
    $self->app->VERSION, $self->app->full_arg0;
}

1;
