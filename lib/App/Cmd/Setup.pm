use strict;
use warnings;
package App::Cmd::Setup;

use App::Cmd ();
use App::Cmd::Command ();
use App::Cmd::Plugin ();
use Carp ();
use Data::OptList ();

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

  my $cmd_base = $into->_default_command_base;
  unless (
    eval { $cmd_base->isa( $self->_command_base_class ) }
    or
    eval "require $cmd_base; 1"
  ) {
    my $base = $self->_command_base_class;
    Sub::Install::install_sub({
      code => sub { $base },
      into => $into,
      as   => '_default_command_base',
    });
  }

  my @plugins;
  for my $plugin (@{ $val->{plugins} || [] }) {
    unless (eval { $plugin->isa($self->_plugin_base_class) }) {
      eval "require $plugin; 1" or die "couldn't load plugin $plugin: $@";
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
