package Test::MyCmd::Command::exit;

use strict;
use warnings;

use base qw(App::Cmd::Command);

=head1 NAME

Test::MyCmd::Command::exit - exit with a given value

=head1 DESCRIPTION

This package exists to exiting with exit();

=cut

sub execute {
  my ($self, $opt, $args) = @_;
  exit(defined $args->[0] ? $args->[0] : 0);
}

1;
