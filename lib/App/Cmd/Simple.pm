use strict;
use warnings;

package App::Cmd::Simple;
use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command' }

our $VERSION = '0.011';

use App::Cmd;
use Sub::Install;

=head1 NAME

App::Cmd::Simple - a helper for building one-command App::Cmd applications

=head1 SYNOPSIS

in F<simplecmd>:

  use YourApp::Cmd;
  Your::Cmd->run;

in F<YourApp/Cmd.pm>:

  package YourApp::Cmd;
  use base qw(App::Cmd::Simple);

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

=head2 validate_args

  $cmd->validate_args(\%opt, \@args);

This method is passed a hashref of command line options (as processed by
Getopt::Long::Descriptive) and an arrayref of leftover arguments.  It may throw
an exception (preferably by calling C<usage_error>) if they are invalid, or it
may do nothing to allow processing to continue.

=head2 run

  Your::App::Cmd::Simple->run(\%opt, \@args);

This method does whatever it is the command should do!  It is passed a hash
reference of the parsed command-line options and an array reference of left
over arguments.

=cut

# Okay, so this is full-on evil, but... whatchagonna do?  It's rjbs's own damn
# fault for calling the run method "run" in both Cmd and Command.
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
  return if $class->_cmd_pkg;

  # I doubt the $i will ever be needed, but let's start paranoid.
  my $generated_name = join('::', $class, 'Cmd', $i++);

  {
    no strict 'refs';
    *{$generated_name . '::ISA'} = [ 'App::Cmd' ];
  }

  Sub::Install::install_sub({
    into => $class,
    as   => '_cmd_pkg',
    code => sub { $generated_name },
  });

  Sub::Install::reinstall_sub({
    into => $class,
    as   => "__$i", # cheap trick -- rjbs, 2007-10-09
    code => $class->can('run'),
  });

  Sub::Install::install_sub({
    into => $generated_name,
    as   => '_command',
    code => sub { { only => $class } },
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

      return ('only', $args);
    },
  });

  # required to make compilation packages correct for caller
  eval qq[
    no warnings 'redefine';
    package $class;
    sub run {
      my \$caller = caller;
      return shift->__$i(\@_) if \$caller eq 'App::Cmd';
      return ${generated_name}->new({
        no_help_plugin     => 1,
        no_commands_plugin => 1,
      })->run(\@_);
    }
  ];
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

=head1 AUTHOR AND COPYRIGHT

Copyright 2007, (code (simply)).  All rights reserved;  App::Cmd and
bundled code are free software, released under the same terms as perl itself.

App::Cmd::Simple was originally written by Ricardo SIGNES in 2007.

=cut

1;
