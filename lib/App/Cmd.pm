package Rubric::CLI;

=head1 NAME

Rubric::CLI - the Rubric command line interface

=head1 VERSION

 $Id$

=cut

use strict;
use warnings;

use Getopt::Long::Descriptive;
use Module::Pluggable::Object;
use UNIVERSAL::moniker;
use UNIVERSAL::require;

sub plugins {
  my ($class) = @_;
  $class = ref $class if ref $class;

  my $finder = Module::Pluggable::Object->new(
    search_path => "$class\::Command",
  );

  my %plugin;
  for ($finder->plugins) {
    my $command = lc $_->moniker;

    die "two plugins exist for command $command: $_ and $plugin{$command}\n"
      if exists $plugin{$command};

    $plugin{$command} = $_;
  }

  return \%plugin;
}

sub new {
  my ($class) = @_;

  my $plugin = $class->plugins;

  bless { plugin => $plugin } => $class;
}

=head1 METHODS

=head2 C< commands >

This returns the commands currently provided by Rubric::CLI plugins.

=cut

sub commands {
  my ($self) = @_;
  keys %{ $self->{plugin} };
}

=head2 C< plugin_for >

  my $plugin = Rubric::CLI->plugin_for($command);

This method requires and returns the plugin (module) for the given command.  If
no plugin implements the command, it returns false.

=cut

sub plugin_for {
  my ($self, $command) = @_;
  return unless exists $self->{plugin}{ $command };

  my $plugin = $self->{plugin}{ $command };
  $plugin->require or die $@;

  return $plugin;
}

sub get_command {
  my ($self) = @_;

  my $command = shift @ARGV;
     $command = 'commands' unless defined $command;

  return $command;
}

sub run {
  my ($self) = @_;

  # 1. figure out first-level dispatch
  my $command = $self->get_command;

  # 2. find its plugin
  #    or else call default plugin
  #    which is help by default..?
  my $plugin = $self->plugin_for($command);
     $plugin = $self->plugin_for('commands') unless $command;

  # 3. use GLD with plugin's usage_desc and opt_spec
  #    this stores the $usage object in the current object
  my ($opt, $usage) = Getopt::Long::Descriptive::describe_options(
    $plugin->usage_desc,
    $plugin->opt_spec,
  );

  my $args = [ @ARGV ];

  # 4. call plugin's run method, pass in opts
  my $cmd = $plugin->new({ app => $self, usage => $usage });

  $cmd->validate_args($opt, $args);

  $cmd->run($opt, $args);
}

1;
