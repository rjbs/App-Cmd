package Test::MySimple;
use strict;
use warnings;
use base 'App::Cmd::Simple';

use Data::Dumper;

sub execute {
  my ($self, $opt, $args) = @_;

  local $Data::Dumper::Terse = 1;
  print Dumper([ $opt, $args ]);
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("not enough args") unless @$args > 0;
}

sub opt_spec {
  return [ "fooble|f", "check all foobs for foobling" ],
}

1;
