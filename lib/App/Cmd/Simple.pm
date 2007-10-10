use strict;
use warnings;

package App::Cmd::Simple;
use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command' }

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

App::Cmd::Simple is not rich in black magic, but it does do some somewhat
gnarly things to make an App::Cmd::Simple look as much like an
App::Cmd::Command as possible.  This means that you can't deviate too much from
the sort of thing shown in the synopsis as you might like.  If you're doing
something other than writing a fairly simple command, and you want to screw
around with the App::Cmd-iness of your program, Simple might not be the best
choice.

=cut

1;
