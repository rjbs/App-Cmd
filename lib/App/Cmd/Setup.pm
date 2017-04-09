use strict;
use warnings;
package App::Cmd::Setup;

# ABSTRACT: helper for setting up App::Cmd classes

=head1 OVERVIEW

App::Cmd::Setup is a helper library, used to set up base classes that will be
used as part of an App::Cmd program.  For the most part you should refer to
L<the tutorial|App::Cmd::Tutorial> for how you should use this library.

This class is useful in three scenarios:

=begin :list

= when writing your App::Cmd subclass

Instead of writing:

  package MyApp;
  use base 'App::Cmd';

...you can write:

  package MyApp;
  use App::Cmd::Setup -app;

The benefits of doing this are mostly minor, and relate to sanity-checking your
class.  The significant benefit is that this form allows you to specify
plugins, as in:

  package MyApp;
  use App::Cmd::Setup -app => { plugins => [ 'Prompt' ] };

Plugins are described in L<App::Cmd::Tutorial>.

= when writing abstract base classes for commands

That is: when you write a subclass of L<App::Cmd::Command> that is intended for
other commands to use as their base class, you should use App::Cmd::Setup.  For
example, if you want all the commands in MyApp to inherit from MyApp::Command,
you may want to write that package like this:

  package MyApp::Command;
  use App::Cmd::Setup -command;

Do not confuse this with the way you will write specific commands:

  package MyApp::Command::mycmd;
  use MyApp -command;

Again, this form mostly performs some validation and setup behind the scenes
for you.  You can use C<L<base>> if you prefer.

= when writing App::Cmd plugins

L<App::Cmd::Plugin> is a mechanism that allows an App::Cmd class to inject code
into all its command classes, providing them with utility routines.

To write a plugin, you must use App::Cmd::Setup.  As seen above, you must also
use App::Cmd::Setup to set up your App::Cmd subclass if you wish to consume
plugins.

For more information on writing plugins, see L<App::Cmd::Manual> and
L<App::Cmd::Plugin>.

=end :list

=cut

use App::Cmd ();
use App::Cmd::Command ();
use App::Cmd::Plugin ();
use Carp ();
use Data::OptList ();
use String::RewritePrefix ();

# 0.06 is needed for load_optional_class
use Class::Load 0.06 qw();

use Sub::Exporter -setup => {
  -as     => '_import',
  exports => [ qw(foo) ],
  collectors => [
    -app     => \'_make_app_class',
    -command => \'_make_command_class',
    -plugin  => \'_make_plugin_class',
  ],
};

sub import {
  goto &_import;
}

sub _app_base_class { 'App::Cmd' }

sub _make_app_class {
  my ($self, $val, $data) = @_;
  my $into = $data->{into};

  $val ||= {};
  Carp::confess "invalid argument to -app setup"
    if grep { $_ ne 'plugins' } keys %$val;

  Carp::confess "app setup requested on App::Cmd subclass $into"
    if $into->isa('App::Cmd');

  $self->_make_x_isa_y($into, $self->_app_base_class);

  if ( ! Class::Load::load_optional_class( $into->_default_command_base ) ) {
    my $base = $self->_command_base_class;
    Sub::Install::install_sub({
      code => sub { $base },
      into => $into,
      as   => '_default_command_base',
    });
  }

  # TODO Check this is right. -- kentnl, 2010-12
  #
  #  my $want_plugin_base = $self->_plugin_base_class;
  my $want_plugin_base = 'App::Cmd::Plugin';

  my @plugins;
  for my $plugin (@{ $val->{plugins} || [] }) {
    $plugin = String::RewritePrefix->rewrite(
      {
        ''  => 'App::Cmd::Plugin::',
        '=' => ''
      },
      $plugin,
    );
    Class::Load::load_class( $plugin );
    unless( $plugin->isa( $want_plugin_base ) ){
        die "$plugin is not a " . $want_plugin_base;
    }
    push @plugins, $plugin;
  }

  Sub::Install::install_sub({
    code => sub { @plugins },
    into => $into,
    as   => '_plugin_plugins',
  });

  return 1;
}

sub _command_base_class { 'App::Cmd::Command' }

sub _make_command_class {
  my ($self, $val, $data) = @_;
  my $into = $data->{into};

  Carp::confess "command setup requested on App::Cmd::Command subclass $into"
    if $into->isa('App::Cmd::Command');

  $self->_make_x_isa_y($into, $self->_command_base_class);

  return 1;
}

sub _make_x_isa_y {
  my ($self, $x, $y) = @_;

  no strict 'refs';
  push @{"$x\::ISA"}, $y;
}

sub _plugin_base_class { 'App::Cmd::Plugin' }
sub _make_plugin_class {
  my ($self, $val, $data) = @_;
  my $into = $data->{into};

  Carp::confess "plugin setup requested on App::Cmd::Plugin subclass $into"
    if $into->isa('App::Cmd::Plugin');

  Carp::confess "plugin setup requires plugin configuration" unless $val;

  $self->_make_x_isa_y($into, $self->_plugin_base_class);

  # In this special case, exporting everything by default is the sensible thing
  # to do. -- rjbs, 2008-03-31
  $val->{groups} = [ default => [ -all ] ] unless $val->{groups};

  my @exports;
  for my $pair (@{ Data::OptList::mkopt($val->{exports}) }) {
    push @exports, $pair->[0], ($pair->[1] || \'_faux_curried_method');
  }

  $val->{exports} = \@exports;

  Sub::Exporter::setup_exporter({
    %$val,
    into => $into,
    as   => 'import_from_plugin',
  });

  return 1;
}

1;
