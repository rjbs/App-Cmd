package App::Cmd::Command;
use base qw/App::Cmd::ArgProcessor/;

=head1 NAME

App::Cmd::Command - a base class for App::Cmd commands

=head1 VERSION

 $Id$

=cut

use strict;
use warnings;

use Carp ();

=head1 METHODS

=head2 new

This returns a new instance of the command plugin.

=cut

sub new {
  my ($class, $arg) = @_;
  bless $arg => $class;
}

=head2 prepare

  my ( $cmd, $opt, $args ) = $class->prepare( @args );

Return a command object parse the command line options, arguments, etc.

=cut

sub prepare {
  my ( $class, $app, @args ) = @_;

  my ($opt, $args, %fields) = $class->_process_args( \@args, $class->_option_processing_params($app) );

  return (
    $class->new({ app => $app, %fields }),
    $opt,
    @$args,
  );
}

sub _option_processing_params {
  my ( $class, @args ) = @_;

  return (
    $class->usage_desc(@args),
    $class->opt_spec(@args),
  );
}

=head2 run

  $command_plugin->run($opt, $arg);

This method does whatever it is the command should do!  It is passed a hash
reference of the parsed command-line options and an array reference of left
over arguments.

=cut

sub run {
  my ($class) = @_;
  Carp::croak "$class does not implement mandatory method 'run'\n";
}

=head2 app

This method returns the App::Cmd object into which this command is plugged.

=cut

sub app { $_[0]->{app}; }

=head2 usage

This method returns the usage object for this command.  (See
L<Getopt::Long::Descriptive>).

=cut

sub usage { $_[0]->{usage}; }

=head2 command_names

This method returns a list of command names handled by this plugin.  If this
method is not overridden by a App::Cmd::Command subclass, it will return the
last part of the plugin's package name, converted to lowercase.

For example, YourApp::Cmd::Command::Init will, by default, handle the command
"init"

=cut

sub command_names {
  # from UNIVERSAL::moniker
  (ref( $_[0] ) || $_[0]) =~ /([^:]+)$/;
  return lc $1;
}

=head2 usage_desc

This method should be overridden to provide a usage string.  (This is the first
argument passed to C<describe_options> from Getopt::Long::Descriptive.)

If not overridden, it returns "%c COMMAND %o";  COMMAND is the first item in
the result of the C<command_names> method.

=cut

sub usage_desc {
  my ($self) = @_;

  my ($app) = $0 =~ m{([^/]+)$};
  $app = 'COMMAND' unless defined $app;
  my ($command) = $self->command_names;
  return "$app $command %o"
}

=head2 opt_spec

This method should be overridden to provide option specifications.  (This is
list of arguments passed to C<describe_options> from Getopt::Long::Descriptive,
after the first.)

If not overridden, it returns an empty list.

=cut

sub opt_spec {
  return;
}

=head2 validate_args

  $command_plugin->validate_args($opt, $arg);

This method is passed a hashref of command line options (as processed by
Getopt::Long::Descriptive) and an arrayref of leftover arguments.  It may throw
an exception if they are invalid, or may do nothing to allow processing to
continue.

=cut

sub validate_args {}

=head2 usage_error

  $self->usage_error("Your mother!");

Used to die with nice usage output, durinv C<validate_args>.

=cut

sub usage_error {
  my ( $self, $error ) = @_;
  die "$error\n\nUsage:\n\n" . $self->_usage_text;
}

sub _usage_text {
  my $self = shift;
  local $@;
  join("\n\n", eval { $self->app->_usage_text }, eval { $self->usage->text } );
}

=head2 abstract

This method returns a short description of the command's purpose.  If this
method is not overriden, it will return the abstract from the module's POD.  If
it can't find the abstract, it will return the string "(unknown")

=cut

# stolen from ExtUtils::MakeMaker
sub abstract {
  my ($class) = @_;
  $class = ref $class if ref $class;

  my $result;

  (my $pm_file = $class) =~ s!::!/!g;
  $pm_file .= '.pm';
  $pm_file = $INC{$pm_file};
  open my $fh, "<", $pm_file or return "(unknown)";

  local $_;
  local $/ = "\n";
  my $inpod = 0;
  while (<$fh>) {
    $inpod = /^=(?!cut)/ ? 1
           : /^=cut/     ? 0
           :               $inpod;
    next unless $inpod;
    chomp;
    next unless /^($class\s-\s)(.*)/;
    $result = $2;
    last;
  }
  return $result || "(unknown)";
}

=head1 AUTHOR AND COPYRIGHT

See L<App::Cmd>.

=cut

1;
