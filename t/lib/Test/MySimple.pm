package Test::MySimple;
use strict;
use warnings;
use base 'App::Cmd::Simple';

use Data::Dumper;

sub run {
  # warn Dumper(\@_);
  print "hi!!\n";
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("not enough args") unless @$args > 1;
}

sub opt_spec {
  return [ "fooble|f", "check all foobs for foobling" ],
}

1;
