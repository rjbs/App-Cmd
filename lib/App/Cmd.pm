use strict;
use warnings;
use 5.006;

package App::Cmd;
use App::Cmd::ArgProcessor;
BEGIN { our @ISA = 'App::Cmd::ArgProcessor' };

use File::Basename ();
use Module::Pluggable::Object ();

use Sub::Exporter -setup => {
  collectors => {
    -command => \'_setup_command',
    -run     => sub { $_[1]->{class}->run; 1 },
  },
};

sub _setup_command {
  my ($self, $val, $data) = @_;
  my $into = $data->{into};

  Carp::confess "App::Cmd -command setup requested for already-setup class"
    if $into->isa('App::Cmd::Command');

  {
    my $base = $self->_default_command_base;
    eval "require $base; 1" or die $@;
    no strict 'refs';
    push @{"$into\::ISA"}, $base;
  }

  $self->_register_command($into);

  for my $plugin ($self->_plugin_plugins) {
    $plugin->import_from_plugin({ into => $into });
  }

  1;
}

sub _plugin_plugins { return }

=head1 NAME

App::Cmd - write command line apps with less suffering

=head1 VERSION

version 0.202

=cut

our $VERSION = '0.202';

=head1 SYNOPSIS

in F<yourcmd>:

  use YourApp -run;

in F<YourApp.pm>:

  package YourApp;
  use App::Cmd::Setup -app;
  1;

in F<YourApp/Command/blort.pm>:

  package YourApp::Command::blort;
  use YourApp -command;
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
    $self->usage_error("No args allowed") if @$args;
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

=head1 METHODS

=head2 new

  my $cmd = App::Cmd->new(\%arg);

This method returns a new App::Cmd object.  During initialization, command
plugins will be loaded.

Valid arguments are:

  no_commands_plugin - if true, the command list plugin is not added

  no_help_plugin     - if true, the help plugin is not added

  plugin_search_path - The path to search for commands in. Defaults to
                       results of plugin_search_path method

If C<no_commands_plugin> is not given, App::Cmd::Command::commands will be
required, and it will be registered to handle all of its command names not
handled by other plugins.

If C<no_help_plugin> is not given, App::Cmd::Command::help will be required,
and it will be registered to handle all of its command names not handled by
other plugins. B<Note:> "help" is the default command, so if you do not load
the default help plugin, you should provide our own or override the
C<default_command> method.

=cut

sub new {
  my ($class, $arg) = @_;

  my $arg0 = $0;
  my $base = File::Basename::basename $arg0;

  my $self = {
    command   => $class->_command($arg),
    arg0      => $base,
    full_arg0 => $arg0,
  };
  
  bless $self => $class;
}
 
# effectively, returns the command-to-plugin mapping guts of a Cmd
# if called on a class or on a Cmd with no mapping, construct a new hashref
# suitable for use as the object's mapping
sub _command {
  my ($self, $arg) = @_;

  return $self->{command} if ref $self and $self->{command};

  my %plugin;
  for my $plugin ($self->_plugins) {
    eval "require $plugin" or die "couldn't load $plugin: $@"
      unless eval { $plugin->isa( $self->_default_command_base ) };
    next unless $plugin->can("command_names");
    foreach my $command (map { lc } $plugin->command_names) {
      die "two plugins for command $command: $plugin and $plugin{$command}\n"
        if exists $plugin{$command};

      $plugin{$command} = $plugin;
    }
  }

  $self->_load_default_plugin($_, $arg, \%plugin) for qw(commands help);

  return \%plugin;
}

# ->_plugins won't be called more than once on any given App::Cmd, but since
# finding plugins can be a bit expensive, we'll do a lousy cache here.
# -- rjbs, 2007-10-09
my %plugins_for;
sub _plugins {
  my ($self) = @_;
  my $class = ref $self || $self;

  return @{ $plugins_for{$class} } if $plugins_for{$class};

  my $finder = Module::Pluggable::Object->new(
    search_path => $self->plugin_search_path,
    $self->_module_pluggable_options,
  );

  my @plugins = $finder->plugins;
  $plugins_for{$class} = \@plugins;

  return @plugins;
}

sub _register_command {
  my ($self, $cmd_class) = @_;
  $self->_plugins;

  my $class = ref $self || $self;
  push @{ $plugins_for{ $class } }, $cmd_class
    unless grep { $_ eq $cmd_class } @{ $plugins_for{ $class } };
}

sub _module_pluggable_options {
  # my ($self) = @_; # no point in creating these ops, just to toss $self
  return;
}

# load one of the stock plugins, unless requested to squash; unlike normal
# plugin loading, command-to-plugin mapping conflicts are silently ignored
sub _load_default_plugin {
  my ($self, $plugin_name, $arg, $plugin_href) = @_;
  unless ($arg->{"no_$plugin_name\_plugin"}) {
    my $plugin = "App::Cmd::Command::$plugin_name";
    eval "require $plugin" or die "couldn't load $plugin: $@";
    for my $command (map { lc } $plugin->command_names) {
      $plugin_href->{$command} ||= $plugin;
    }
  }
}

=head2 run

  $cmd->run;

This method runs the application.  If called the class, it will instantiate a
new App::Cmd object to run.

It determines the requested command (generally by consuming the first
command-line argument), finds the plugin to handle that command, parses the
remaining arguments according to that plugin's rules, and runs the plugin.

It passes the contents of the global argument array (C<@ARGV>) to
L</C<prepare_command>>, but C<@ARGV> is not altered by running an App::Cmd.

=cut

sub run {
  my ($self) = @_;

  # We should probably use Class::Default.
  $self = $self->new unless ref $self;

  # prepare the command we're going to run...
  my ($cmd, $opt, @args) = $self->prepare_command(@ARGV);
   
  # ...and then run it
  $self->execute_command($cmd, $opt, @args);
}

=head2 arg0

=head2 full_arg0

  my $program_name = $app->arg0;

  my $full_program_name = $app->full_arg0;

These methods return the name of the program invoked to run this application.
This is determined by inspecting C<$0> when the App::Cmd object is
instantiated, so it's probably correct, but doing weird things with App::Cmd
could lead to weird values from these methods.

If the program was run like this:

  knight!rjbs$ ~/bin/rpg dice 3d6

Then the methods return:

  arg0      - rpg
  full_arg0 - /Users/rjbs/bin/rpg

These values are captured when the App::Cmd object is created, so it is safe to
assign to C<$0> later.

=head2 prepare_command

  my ($cmd, $opt, @args) = $app->prepare_command(@ARGV);

This method will load the plugin for the requested command, use its options to
parse the command line arguments, and eventually return everything necessary to
actually execute the command.

=cut

sub prepare_command {
  my ($self, @args) = @_;

  # figure out first-level dispatch
  my ($command, $opt, @sub_args) = $self->get_command(@args);

  # set up the global options (which we just determined)
  $self->set_global_options($opt);

  # find its plugin or else call default plugin (default default is help)
  if ($command) {
    $self->_prepare_command($command, $opt, @sub_args);
  } else {
    $self->_prepare_default_command($opt, @sub_args);
  }
}

sub _prepare_command {
  my ($self, $command, $opt, @args) = @_;
  if (my $plugin = $self->plugin_for($command)) {
    return $plugin->prepare($self, @args);
  } else {
    return $self->_bad_command($command, $opt, @args);
  }
}

sub _prepare_default_command {
  my ($self, $opt, @sub_args) = @_;
  $self->_prepare_command($self->default_command, $opt, @sub_args);
}

sub _bad_command {
  my ($self, $command, $opt, @args) = @_;
  print "Unrecognized command: $command.\n\nUsage:\n" if defined($command);

  # This should be class data so that, in Bizarro World, two App::Cmds will not
  # conflict.
  our $_bad++;
  $self->prepare_command("commands");
}

END { exit 1 if our $_bad };

=head2 default_command

This method returns the name of the command to run if none is given on the
command line.  The default default is "help"

=cut

sub default_command { "help" }

=head2 execute_command

  $app->execute_command($cmd, \%opt, @args);

This method will invoke C<validate_args> and then C<run> on C<$cmd>.

=cut

sub execute_command {
  my ($self, $cmd, $opt, @args) = @_;

  local our $active_cmd = $cmd;

  $cmd->validate_args($opt, \@args);
  $cmd->run($opt, \@args);
}

=head2 plugin_search_path

This method returns the plugin_search_path as set.  The default implementation,
if called on "YourApp::Cmd" will return "YourApp::Cmd::Command"

This is a method because it's fun to override it with, for example:

  use constant plugin_search_path => __PACKAGE__;

=cut

sub _default_command_base {
  my ($self) = @_;
  my $class = ref $self || $self;
  return "$class\::Command";
}

sub _default_plugin_base {
  my ($self) = @_;
  my $class = ref $self || $self;
  return "$class\::Plugin";
}

sub plugin_search_path {
  my ($self) = @_;

  my $dcb = $self->_default_command_base;
  my $ccb = $dcb eq 'App::Cmd::Command'
          ? $self->App::Cmd::_default_command_base
          : $self->_default_command_base;

  my @default = ($ccb, $self->_default_plugin_base);

  if (ref $self) {
    return $self->{plugin_search_path} ||= \@default;
  } else {
    return \@default;
  }
}

=head2 global_options

  if ($cmd->app->global_options->{verbose}) { ... }

This method returns the running application's global options as a hashref.  If
there are no options specified, an empty hashref is returend.

=cut

sub global_options {
	my $self = shift;
	return $self->{global_options} ||= {} if ref $self;
  return {};
}

=head2 set_global_options

  $app->set_global_options(\%opt);

This method sets the global options.

=cut

sub set_global_options {
  my ($self, $opt) = @_;
  return $self->{global_options} = $opt;
}

=head2 command_names

  my @names = $cmd->command_names;

This returns the commands names which the App::Cmd object will handle.

=cut

sub command_names {
  my ($self) = @_;
  keys %{ $self->_command };
}

=head2 command_plugins

  my @plugins = $cmd->command_plugins;

This method returns the package names of the plugins that implement the
App::Cmd object's commands.

=cut

sub command_plugins {
  my ($self) = @_;
  my %seen = map {; $_ => 1 } values %{ $self->_command };
  keys %seen;
}

=head2 plugin_for

  my $plugin = $cmd->plugin_for($command);

This method returns the plugin (module) for the given command.  If no plugin
implements the command, it returns false.

=cut

sub plugin_for {
  my ($self, $command) = @_;
  return unless exists $self->_command->{ $command };

  return $self->_command->{ $command };
}

=head2 get_command

  my ($command_name, $opt, @args) = $app->get_command(@args);

Process arguments and into a command name and (optional) global options.

=cut

sub get_command {
  my ($self, @args) = @_;

  my ($opt, $args, %fields)
    = $self->_process_args(\@args, $self->_global_option_processing_params);

  my ($command, $rest) = $self->_cmd_from_args($args);

  $self->{usage} = $fields{usage};

  return ($command, $opt, @$rest);
}

sub _cmd_from_args {
  my ($self, $args) = @_;

  my $command = shift @$args;
  return ($command, $args);
}

sub _global_option_processing_params {
  my ($self, @args) = @_;

  return (
    $self->usage_desc(@args),
    $self->global_opt_spec(@args),
    { getopt_conf => [qw/pass_through/] },
  );
}

=head2 usage

  print $self->app->usage->text;

Returns the usage object for the global options.

=cut

sub usage { $_[0]{usage} };

=head2 usage_desc

The top level usage line. Looks something like

  "yourapp [options] <command>"

=cut

sub usage_desc {
  # my ($self) = @_; # no point in creating these ops, just to toss $self
  return "%c %o <command>";
}

=head2 global_opt_spec

Returns an empty list. Can be overridden for pre-dispatch option processing.
This is useful for flags like --verbose.

=cut

sub global_opt_spec {
  # my ($self) = @_; # no point in creating these ops, just to toss $self
  return;
}

=head2 usage_error

  $self->usage_error("Your mother!");

Used to die with nice usage output, during C<validate_args>.

=cut

sub usage_error {
  my ($self, $error) = @_;
  die "Error: $error\nUsage: " . $self->_usage_text;
}

sub _usage_text {
  my ($self) = @_;
  my $text = $self->usage->text;
  $text =~ s/\A(\s+)/!/;
  return $text;
}

=head1 TODO

=over

=item * publish and bring in Log::Speak (simple quiet/verbose output)

=item * publish and use our internal enhanced describe_options

=item * publish and use our improved simple input routines

=back

=head1 COPYRIGHT AND AUTHOR 

Copyright 2005-2006, (code (simply)).  App::Cmd and bundled code are free
software, released under the same terms as perl itself.

App::Cmd was originally written as Rubric::CLI by Ricardo SIGNES in 2005.  It
was refactored extensively by Ricardo SIGNES and John Cappiello and released as
App::Cmd in 2006.  Yuval Kogman performed significant refactoring and other
improvements on the code.

=cut

1;
