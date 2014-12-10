use strict;
use warnings;

package App::Cmd::Subdispatch;

use App::Cmd;
use App::Cmd::Command;
BEGIN { our @ISA = qw(App::Cmd::Command App::Cmd) } 

# ABSTRACT: an App::Cmd::Command that is also an App::Cmd

=method new

A hackish new that allows us to have an Command instance before they normally
exist.

=cut

sub new {
	my ($inv, $fields, @args) = @_;
	if (ref $inv) {
		@{ $inv }{ keys %$fields } = values %$fields;
		return $inv;
	} else {
		$inv->SUPER::new($fields, @args);
	}
}

=method prepare

  my $subcmd = $subdispatch->prepare($app, @args);

An overridden version of L<App::Cmd::Command/prepare> that performs a new
dispatch cycle.

=cut

sub prepare {
	my ($class, $app, @args) = @_;

	my $self = $class->new({ app => $app });

	my ($subcommand, $opt, @sub_args) = $self->get_command(@args);

  $self->set_global_options($opt);

	if (defined $subcommand) {
    return $self->_prepare_command($subcommand, $opt, @sub_args);
  } else {
    if (@args) {
      return $self->_bad_command(undef, $opt, @sub_args);
    } else {
      return $self->prepare_default_command($opt, @sub_args);
    }
  }
}

sub prepare_default_command {
  my ( $self, $opt, @args ) = @_;
  $self->_prepare_command( "help" );
}

sub _plugin_prepare {
  my ($self, $plugin, @args) = @_;
  return $plugin->prepare($self->choose_parent_app($self->app, $plugin), @args);
}

=method app

  $subdispatch->app;

This method returns the application that this subdispatch is a command of.

=cut

sub app { $_[0]{app} }

=method choose_parent_app

  $subcmd->prepare(
    $subdispatch->choose_parent_app($app, $opt, $plugin),
    @$args
  );

A method that chooses whether the parent app or the subdispatch is going to be
C<< $cmd->app >>.

=cut

sub choose_parent_app {
	my ( $self, $app, $plugin ) = @_;

	if (
    $plugin->isa("App::Cmd::Command::commands")
    or $plugin->isa("App::Cmd::Command::help")
    or scalar keys %{ $self->global_options }
  ) {
		return $self;
	} else {
		return $app;
	}
}

1;
