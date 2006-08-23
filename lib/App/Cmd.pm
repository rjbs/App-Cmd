package App::Cmd;

use strict;
use warnings;

=head1 NAME

App::Cmd - write command line apps with less suffering

=head1 VERSION

version 0.002

 $Id$

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

in F<yourcmd>:

  use YourApp::Cmd;
  
  Your::Cmd->new->run;

in F<YourApp/Cmd.pm>:

  package YourApp::Cmd;
  use base qw(App::Cmd);
  1;

in F<YourApp/Cmd/Command/blort.pm>:

  package YourApp::Cmd::Command::blort;
  use strict; use warnings;

  sub opt_spec {
    return (
      [ "blortex|X",  "use the blortex algorithm" ],
      [ "recheck|r",  "recheck all results"       ],
    );
  }

  sub validate_args {
    my ($self, $opt, $args) = @_;

    # no args allowed but options!
    die $self->usage->text if @$args;
  }

  sub run {
    my ($self, $opt, $args) = @_;

    my $result = $opt->{blortex} ? blortex() : blort();

    recheck($result) if $opt->{recheck};

    print $result;
  }

and, finally, at the command line:

  knight!rjbs$ yourcmd blort --recheck

  All blorts successful.

=head1 DESCRIPTION

App::Cmd is intended to make it easy to write complex command-line applications
without having to think about most of the annoying things usually involved.

For information on how to start using App::Cmd, see App::Cmd::Tutorial.

=cut

use Getopt::Long::Descriptive ();
use Module::Pluggable::Object ();

=head1 METHODS

=head2 new

  my $cmd = App::Cmd->new(\%arg);

This method returns a new App::Cmd object.  During initialization, command
plugins will be loaded.

Valid arguments are:

  no_commands_plugin - if true, the command list plugin is not added

If C<no_commands_plugin> is not given, App::Cmd::Command::commands will be
required, and it will be registered to handle all of its command names not
handled by other plugins.

=cut

sub new {
  my ($class, $arg) = @_;

  my $self = { command => $class->_command($arg) };
  
  bless $self => $class;
}

sub _plugin_search_path {
  my $self = shift;
  my $class = ref $self ? ref $self : $self;
  "$class\::Command",
}

sub _module_pluggable_options {
  my $self = shift;
  return ();
}

sub _command {
  my ($self, $arg) = @_;

  return $self->{command} if (ref($self) and $self->{command});


  my $finder = Module::Pluggable::Object->new(
    search_path => $self->_plugin_search_path(),
    $self->_module_pluggable_options(),
  );

  my %plugin;
  for my $plugin ($finder->plugins) {
    eval "require $plugin" or die "couldn't load $plugin: $@";
    foreach my $command ( map { lc } $plugin->command_names) {
      die "two plugins for command $command: $plugin and $plugin{$command}\n"
        if exists $plugin{$command};

      $plugin{$command} = $plugin;
    }
  }

  unless ($arg->{no_commands_plugin}) {
    my $plugin = 'App::Cmd::Command::commands';
    eval "require $plugin" or die "couldn't load $plugin: $@";
    for ($plugin->command_names) {
      my $command = lc $_;

      $plugin{$command} = $plugin unless exists $plugin{$command};
    }
  }
    
  return \%plugin;
}

=head2 C< command_names >

  my @names = $cmd->command_names;

This returns the commands names which the App::Cmd object will handle.

=cut

sub command_names {
  my ($self) = @_;
  keys %{ $self->_command };
}

=head2 C< command_plugins >

  my @plugins = $cmd->command_plugins;

This 

=cut

sub command_plugins {
  my ($self) = @_;
  my %seen = map {; $_ => 1 } values %{ $self->_command };
  keys %seen;
}

=head2 C< plugin_for >

  my $plugin = $cmd->plugin_for($command);

This method requires and returns the plugin (module) for the given command.  If
no plugin implements the command, it returns false.

=cut

sub plugin_for {
  my ($self, $command) = @_;
  return unless exists $self->_command->{ $command };

  my $plugin = $self->_command->{ $command };

  return $plugin;
}

# This method returns the command to handle.  It should probably be public so
# it can be subclassed for great justice. -- rjbs, 2006-06-11
sub _get_command {
  my ($self) = @_;

  my $command = shift @ARGV;
     $command = 'commands' unless defined $command;

  return $command;
}

=head2 C< run >

  $cmd->run;

This method runs the application.  If called the class, it will instantiate a
new App::Cmd object to run.

It determines the requested command (generally by consuming the first
command-line argument), finds the plugin to handle that command, parses the
remaining arguments according to that plugin's rules, and runs the plugin.

=cut

sub run {
  my ($self) = @_;

  # We should probably use Class::Default.
  $self = $self->new unless ref $self;

  # 1. figure out first-level dispatch
  my $command = $self->_get_command;

  # 2. find its plugin
  #    or else call default plugin
  #    which is help by default..?
  my $plugin = $self->plugin_for($command);
     $plugin = $self->plugin_for('commands') unless $command;

  die "Unrecognized command: $command\ntry '$0 commands' for a command listing\n" unless $plugin;

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

=head1 TODO

Lots of stuff!  This list isn't close to complete yet, I'm still adding to it.

=over

=item * improve the tutorial

=item * publish and bring in Log::Speak (simple quiet/verbose output)

=item * publish and use our internal enhanced describe_options

=item * publish and use our improved simple input routines

=item * publish and use our remaining little CLI tools

=item * make it simple to write a command with no subcommands

=back

=head1 AUTHOR AND COPYRIGHT

Copyright 2005-2006, (code (simply)).  All rights reserved;  App::Cmd and
bundled code are free software, released under the same terms as perl itself.

App:Cmd was originally written as Rubric::CLI by Ricardo SIGNES in 2005.  It
was refactored extensively by Ricardo SIGNES and John Cappiello and released as
App::Cmd in 2006.

=cut

1;
