use strict;
use warnings;

package App::Cmd::Command;
use App::Cmd::ArgProcessor;
BEGIN { our @ISA = 'App::Cmd::ArgProcessor' };

=head1 NAME

App::Cmd::Command - a base class for App::Cmd commands

=head1 VERSION

version 0.302

=cut

our $VERSION = '0.302';

use Carp ();

=head1 METHODS

=head2 prepare

  my ($cmd, $opt, $args) = $class->prepare($app, @args);

This method is the primary way in which App::Cmd::Command objects are built.
Given the remaining command line arguments meant for the command, it returns
the Command object, parsed options (as a hashref), and remaining arguments (as
an arrayref).

In the usage above, C<$app> is the App::Cmd object that is invoking the
command.

=cut

sub prepare {
  my ($class, $app, @args) = @_;

  my ($opt, $args, %fields)
    = $class->_process_args(\@args, $class->_option_processing_params($app));

  return (
    $class->new({ app => $app, %fields }),
    $opt,
    @$args,
  );
}

sub _option_processing_params {
  my ($class, @args) = @_;

  return (
    $class->usage_desc(@args),
    $class->opt_spec(@args),
  );
}

=head2 new

This returns a new instance of the command plugin.  Probably only C<prepare>
should use this.

=cut

sub new {
  my ($class, $arg) = @_;
  bless $arg => $class;
}

=head2 execute

=for Pod::Coverage run

  $command_plugin->execute(\%opt, \@args);

This method does whatever it is the command should do!  It is passed a hash
reference of the parsed command-line options and an array reference of left
over arguments.

If no C<execute> method is defined, it will try to call C<run> -- but it will
warn about this behavior during testing, to remind you to fix the method name!

=cut

sub execute {
  my $class = shift;

  if (my $run = $class->can('run')) {
    warn "App::Cmd::Command subclasses should implement ->execute not ->run"
      if $ENV{HARNESS_ACTIVE};

    return $class->$run(@_);
  }

  Carp::croak ref($class) . " does not implement mandatory method 'execute'\n";
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

  my ($command) = $self->command_names;
  return "%c $command %o"
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

  $command_plugin->validate_args(\%opt, \@args);

This method is passed a hashref of command line options (as processed by
Getopt::Long::Descriptive) and an arrayref of leftover arguments.  It may throw
an exception (preferably by calling C<usage_error>, below) if they are invalid,
or it may do nothing to allow processing to continue.

=cut

sub validate_args { }

=head2 usage_error

  $self->usage_error("This command must not be run by root!");

This method should be called to die with human-friendly usage output, during
C<validate_args>.

=cut

sub usage_error {
  my ( $self, $error ) = @_;
  die "Error: $error\nUsage: " . $self->_usage_text;
}

sub _usage_text {
  my ($self) = @_;
  local $@;
  join "\n", eval { $self->app->_usage_text }, eval { $self->usage->text };
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

  local $/ = "\n";
  my $inpod;

  while (local $_ = <$fh>) {
    $inpod = /^=cut/ ? !$inpod : $inpod || /^=(?!cut)/; # =cut toggles, it doesn't end :-/

    next unless $inpod;
    chomp;
    next unless /^(?:$class\s-\s)(.*)/;
    $result = $1;
    last;
  }
  return $result || "(unknown)";
}

=head2 description

This method should be overridden to provide full option description. It
is used by the help command.

If not overridden, it returns an empty string.

=cut

sub description { '' }


=head1 AUTHOR AND COPYRIGHT

See L<App::Cmd>.

=cut

1;
