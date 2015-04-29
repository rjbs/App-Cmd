use strict;
use warnings;

package App::Cmd::Command;

use App::Cmd::ArgProcessor;
BEGIN { our @ISA = 'App::Cmd::ArgProcessor' };

# ABSTRACT: a base class for App::Cmd commands

use Carp ();

=method prepare

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

=method new

This returns a new instance of the command plugin.  Probably only C<prepare>
should use this.

=cut

sub new {
  my ($class, $arg) = @_;
  bless $arg => $class;
}

=method execute

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

=method app

This method returns the App::Cmd object into which this command is plugged.

=cut

sub app { $_[0]->{app}; }

=method usage

This method returns the usage object for this command.  (See
L<Getopt::Long::Descriptive>).

=cut

sub usage { $_[0]->{usage}; }

=method command_names

This method returns a list of command names handled by this plugin. The
first item returned is the 'canonical' name of the command.

If this method is not overridden by an App::Cmd::Command subclass, it will
return the last part of the plugin's package name, converted to lowercase.
For example, YourApp::Cmd::Command::Init will, by default, handle the command
"init".

Subclasses should generally get the superclass value of C<command_names>
and then append aliases.

=cut

sub command_names {
  # from UNIVERSAL::moniker
  (ref( $_[0] ) || $_[0]) =~ /([^:]+)$/;
  return lc $1;
}

=method usage_desc

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

=method opt_spec

This method should be overridden to provide option specifications.  (This is
list of arguments passed to C<describe_options> from Getopt::Long::Descriptive,
after the first.)

If not overridden, it returns an empty list.

=cut

sub opt_spec {
  return;
}

=method validate_args

  $command_plugin->validate_args(\%opt, \@args);

This method is passed a hashref of command line options (as processed by
Getopt::Long::Descriptive) and an arrayref of leftover arguments.  It may throw
an exception (preferably by calling C<usage_error>, below) if they are invalid,
or it may do nothing to allow processing to continue.

=cut

sub validate_args { }

=method usage_error

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

=method abstract

This method returns a short description of the command's purpose.  If this
method is not overridden, it will return the abstract from the module's Pod.
If it can't find the abstract, it will look for a comment starting with
"ABSTRACT:" like the ones used by L<Pod::Weaver::Section::Name>.

=cut

# stolen from ExtUtils::MakeMaker
sub abstract {
  my ($class) = @_;
  $class = ref $class if ref $class;

  my $result;
  my $weaver_abstract;

  # classname to filename
  (my $pm_file = $class) =~ s!::!/!g;
  $pm_file .= '.pm';
  $pm_file = $INC{$pm_file} or return "(unknown)";

  # if the pm file exists, open it and parse it
  open my $fh, "<", $pm_file or return "(unknown)";

  local $/ = "\n";
  my $inpod;

  while (local $_ = <$fh>) {
    # =cut toggles, it doesn't end :-/
    $inpod = /^=cut/ ? !$inpod : $inpod || /^=(?!cut)/;

    if (/#+\s*ABSTRACT: (.*)/){
      # takes ABSTRACT: ... if no POD defined yet
      $weaver_abstract = $1;
    }

    next unless $inpod;
    chomp;

    next unless /^(?:$class\s-\s)(.*)/;

    $result = $1;
    last;
  }

  return $result || $weaver_abstract || "(unknown)";
}

=method description

This method can be overridden to provide full option description. It
is used by the built-in L<help|App::Cmd::Command::help> command.

If not overridden, it uses L<Pod::Usage> to extract the description
from the module's Pod DESCRIPTION section or the empty string.

=cut

sub description {
    my ($class) = @_;
    $class = ref $class if ref $class;

    # classname to filename
    (my $pm_file = $class) =~ s!::!/!g;
    $pm_file .= '.pm';
    $pm_file = $INC{$pm_file} or return '';

    open my $input, "<", $pm_file or return '';

    my $descr = "";
    open my $output, ">", \$descr;

    require Pod::Usage;
    Pod::Usage::pod2usage( -input => $input,
               -output => $output,
               -exit => "NOEXIT", 
               -verbose => 99,
               -sections => "DESCRIPTION",
               indent => 0
    );
    $descr =~ s/Description:\n//m;
    chomp $descr;

    return $descr;
}

1;
