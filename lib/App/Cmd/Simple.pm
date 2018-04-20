use strict;
use warnings;

package App::Cmd::Simple;

use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command' }

# ABSTRACT: a helper for building one-command App::Cmd applications

use App::Cmd;
use Sub::Install;
use Package::Stash;

=head1 SYNOPSIS

in F<simplecmd>:

  use YourApp::Cmd;
  Your::Cmd->run;

in F<YourApp/Cmd.pm>:

  package YourApp::Cmd;
  use parent qw(App::Cmd::Simple);

  our $VERSION = '0.01';

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

  sub execute {
    my ($self, $opt, $args) = @_;

    my $result = $opt->{blortex} ? blortex() : blort();

    recheck($result) if $opt->{recheck};

    print $result;
  }

and, finally, at the command line:

  knight!rjbs$ simplecmd --recheck

  All blorts successful.

=head1 SUBCLASSING

When writing a subclass of App::Cmd:Simple, there are only a few methods that
you might want to implement.  They behave just like the same-named methods in
App::Cmd.

=head2 opt_spec

This method should be overridden to provide option specifications.  (This is
list of arguments passed to C<describe_options> from Getopt::Long::Descriptive,
after the first.)

If not overridden, it returns an empty list.

=head2 usage_desc

This method should be overridden to provide the top level usage line.
It's a one-line summary of how the command is to be invoked, and
should be given in the format used for the C<$usage_desc> parameter to
C<describe_options> in Getopt::Long::Descriptive.

If not overridden, it returns something that prints out like:

  yourapp [-?h] [long options...]

=head2 validate_args

  $cmd->validate_args(\%opt, \@args);

This method is passed a hashref of command line options (as processed by
Getopt::Long::Descriptive) and an arrayref of leftover arguments.  It may throw
an exception (preferably by calling C<usage_error>) if they are invalid, or it
may do nothing to allow processing to continue.

=head2 execute

  Your::App::Cmd::Simple->execute(\%opt, \@args);

This method does whatever it is the command should do!  It is passed a hash
reference of the parsed command-line options and an array reference of left
over arguments.

=cut

# The idea here is that the user will someday replace "Simple" in his ISA with
# "Command" and then write a standard App::Cmd package.  To make that possible,
# we produce a behind-the-scenes App::Cmd object when the user says 'use
# MyApp::Simple' and redirect MyApp::Simple->run to that.
my $i;
BEGIN { $i = 0 }

sub import {
  my ($class) = @_;
  return if $class eq __PACKAGE__;

  # This signals that something has already set the target up.
  return $class if $class->_cmd_pkg;

  my $core_execute = App::Cmd::Command->can('execute');
  my $our_execute  = $class->can('execute');
  Carp::confess(
    "App::Cmd::Simple subclasses must implement ->execute, not ->run"
  ) unless $our_execute and $our_execute != $core_execute;

  # I doubt the $i will ever be needed, but let's start paranoid.
  my $generated_name = join('::', $class, '_App_Cmd', $i++);

  {
    no strict 'refs';
    *{$generated_name . '::ISA'} = [ 'App::Cmd' ];
  }

  Sub::Install::install_sub({
    into => $class,
    as   => '_cmd_pkg',
    code => sub { $generated_name },
  });

  Sub::Install::install_sub({
      into => $class,
      as => 'command_names',
      code => sub { 'only' },
  });

  Sub::Install::install_sub({
    into => $generated_name,
    as   => '_plugins',
    code => sub { $class },
  });

  Sub::Install::install_sub({
    into => $generated_name,
    as   => 'default_command',
    code => sub { 'only' },
  });

  Sub::Install::install_sub({
    into => $generated_name,
    as   => '_cmd_from_args',
    code => sub {
      my ($self, $args) = @_;
      if (defined(my $command = $args->[0])) {
        my $plugin = $self->plugin_for($command);
        # If help was requested, show the help for the command, not the
        # main help. Because the main help would talk about subcommands,
        # and a "Simple" app has no subcommands.
        if ($plugin and grep { $plugin eq $self->plugin_for($_) } qw( help version ) ) {
          return ($command, [ $self->default_command ]);
        }
        # Any other value for "command" isn't really a command at all --
        # it's the first argument. So call the default command instead.
      }
      return ($self->default_command, $args);
    },
  });

  Package::Stash->new( $generated_name)->add_symbol( '$VERSION', $class->VERSION );


  Sub::Install::install_sub({
    into => $class,
    as   => 'run',
    code => sub {
      $generated_name->new({
        no_help_plugin     => 0,
        no_version_plugin  => 0,
        no_commands_plugin => 1,
      })->run(@_);
    }
  });

  return $class;
}

sub usage_desc {
  return "%c %o"
}

sub _cmd_pkg { }

=head1 WARNINGS

B<This should be considered experimental!>  Although it is probably not going
to change much, don't build your business model around it yet, okay?

App::Cmd::Simple is not rich in black magic, but it does do some somewhat
gnarly things to make an App::Cmd::Simple look as much like an
App::Cmd::Command as possible.  This means that you can't deviate too much from
the sort of thing shown in the synopsis as you might like.  If you're doing
something other than writing a fairly simple command, and you want to screw
around with the App::Cmd-iness of your program, Simple might not be the best
choice.

B<One specific warning...>  if you are writing a program with the
App::Cmd::Simple class embedded in it, you B<must> call import on the class.
That's how things work.  You can just do this:

  YourApp::Cmd->import->run;

=cut

1;
