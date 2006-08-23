package App::Cmd;
use base qw/App::Cmd::ArgProcessor/;

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

use Module::Pluggable::Object ();

=head1 METHODS

=head2 new

  my $cmd = App::Cmd->new(\%arg);

This method returns a new App::Cmd object.  During initialization, command
plugins will be loaded.

Valid arguments are:

  no_commands_plugin - if true, the command list plugin is not added

  plugin_search_path - The path to search for commands in. Defaults to
                       "YourClass::Command"

If C<no_commands_plugin> is not given, App::Cmd::Command::commands will be
required, and it will be registered to handle all of its command names not
handled by other plugins.

=cut

sub new {
  my ($class, $arg) = @_;

  my $self = { command => $class->_command($arg) };
  
  bless $self => $class;
}

=head2 C< plugin_search_path >

Returns the plugin_search_path as set.

This is a method because it's fun to override it with

  use constant plugin_search_path => __PACKAGE__;

and stuff.

=cut

sub plugin_search_path {
  my $self = shift;
  my $class = ref $self || $self;
  my $default = "$class\::Command";

  if ( ref $self ) {
    return $self->{plugin_search_path} ||= $default;
  } else {
    return $default;
  }
}

sub _module_pluggable_options {
  my $self = shift;
  return ();
}

=head2 set_global_options

  $app->set_global_options( { } );

This is a separate method because it's more of a hook than an accessor.

=cut

sub set_global_options {
  my ( $self, $opt ) = @_;
  return $self->{global_options} = $opt;
}

=head2 global_options

  if ( $cmd->app->global_options->{verbose} ) { ... }

This field contains the global options.

=cut

sub global_options {
	my $self = shift;
	return $self->{global_options} ||={} if ref($self);
  return {};
}
 
sub _command {
  my ($self, $arg) = @_;

  return $self->{command} if (ref($self) and $self->{command});


  my $finder = Module::Pluggable::Object->new(
    search_path => $self->plugin_search_path(),
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

  unless ($arg->{no_help_plugin}) {
    my $plugin = 'App::Cmd::Command::help';
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

=head2 get_command

  my ( $command_name, $opt, $args ) = $app->get_command( @args );

Process arguments and into a command name and [optional] global options.

=cut

sub get_command {
  my ($self, @args) = @_;

  my ( $opt, $args, %fields ) = $self->_process_args( \@args, $self->_global_option_processing_params );

  my ( $command, @rest ) = @$args;

  $self->{usage} = $fields{usage};

  return ( $command, $opt, @rest );
}

# FIXME cleanup

=head2 C< usage >

  print $self->app->usage->text;

Returns the usage object for the global options.

=cut

sub usage { $_[0]{usage} };

sub _usage_text {
  my $self = shift;
  local $@;
  join("\n\n", eval { $self->app->_usage_text }, eval { $self->usage->text } );
}

sub _global_option_processing_params {
  my ( $self, @args ) = @_;

  return (
    $self->usage_desc(@args),
    $self->global_opt_spec(@args),
    { getopt_conf => [qw/pass_through/] },
  );
}

=head2 C< usage_desc >

The top level usage line. Looks something like

  "yourapp [options] <command>"

=cut

sub usage_desc {
  my $self = shift;
  return "%c %o <command>";
}

=head2 C< global_opt_spec >

Returns an empty list. Can be overridden for pre-dispatch option processing.
This is useful for flags like --verbose.

=cut

sub global_opt_spec {
  my $self = shift;
  return ();
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

  # 1. prepare the command object
  my ( $cmd, $opt, @args ) = $self->prepare_command( @ARGV );
   
  # 2. call plugin's run method, pass in opts
  $self->execute_command( $cmd, $opt, @args );
}

=head2 C<execute_command>

  $app->execute_command( $cmd, $opt, $args );

This method will invoke C<validate_args> and then C<run> on C<$cmd>.

=cut

sub execute_command {
  my ( $self, $cmd, $opt, @args ) = @_;

  $cmd->validate_args($opt, \@args);

  $cmd->run($opt, \@args);
}

=head2 C<prepare_command>

  my ( $cmd, $opt, $args ) = $app->execute_command( @ARGV );

This method will parse the subcommand, load the plugin for it, use it to parse
the command line options, and eventually return everything necessary to
actually execute the command.

=cut

sub prepare_command {
  my ($self, @args) = @_;

  # 1. figure out first-level dispatch
  my ( $command, $opt, @sub_args ) = $self->get_command( @args );

  $self->set_global_options( $opt );


  # 2. find its plugin
  #    or else call default plugin
  #    which is help by default..?

  if ( defined($command) ) {
    $self->_prepare_command( $command, $opt, @sub_args );
  } else {
    return $self->prepare_default_command( $opt, @sub_args );
  }
}

sub _prepare_command {
  my ( $self, $command, $opt, @args ) = @_;
  if ( my $plugin = $self->plugin_for($command) ) {
    $self->_plugin_prepare( $plugin, @args );
  } else {
    return $self->_bad_command($command, $opt, @args);
  }
}

sub _plugin_prepare {
  my ( $self, $plugin, @args ) = @_;
  return $plugin->prepare( $self, @args );
}

sub _bad_command {
  my ( $self, $command, $opt, @args ) = @_;
  print "Unrecognized command: $command.\n\nUsage:\n\n" if defined($command);
  our $_bad++; END { exit 1 if $_bad };
  $self->execute_command( $self->prepare_command("commands") );
  exit 1;
}

sub prepare_default_command {
  my $self = shift;
  $self->prepare_command("commands");
}

=head2 usage_error

  $self->usage_error("Your mother!");

Used to die with nice usage output, durinv C<validate_args>.

=cut

sub usage_error {
  my ( $self, $error ) = @_;
  die "$error\n\nUsage:\n\n" . $self->_usage_text;
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
