use strict;
use warnings;

package App::Cmd::Command::version;

use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command'; }

# ABSTRACT: display an app's version

=head1 DESCRIPTION

This plugin implements the C<version> command, often invoked by its switch-like
name, C<--version>. On execution it shows the program name, its base class
with version number, and the full program name.

=cut

sub command_names { qw/version --version/ }

sub version_for_display {
  $_[0]->version_package->VERSION
}

sub version_package {
  ref($_[0]->app)
}

sub execute {
  my ($self, $opts, $args) = @_;

  printf "%s (%s) version %s (%s)\n",
    $self->app->arg0, $self->version_package,
    $self->version_for_display, $self->app->full_arg0;
}

1;
