use strict;
use warnings;
package App::Cmd::Setup;

use App::Cmd ();
use App::Cmd::Command ();
use Carp ();

use Sub::Exporter -setup => {
  -as     => '_import',
  exports => [ qw(foo) ],
  collectors => [
    -app     => \'_make_app_class',
    -command => \'_make_command_class',
  ],
};

sub import {
  goto &_import;
}

sub _app_base_class { 'App::Cmd' }

sub _make_app_class {
  my ($self, $val, $data) = @_;
  my $into = $data->{into};

  Carp::confess "App::Cmd::Setup application setup requested on App::Cmd class"
    if $into->isa('App::Cmd');

  {
    no strict 'refs';
    push @{"$into\::ISA"}, $self->_app_base_class;
  }

  return 1;
}

1;
