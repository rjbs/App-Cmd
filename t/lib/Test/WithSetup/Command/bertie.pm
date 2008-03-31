use strict;
use warnings;
package Test::WithSetup::Command::bertie;
use Test::WithSetup -command;

sub run {
  my ($self, $opt, $args) = @_;
  return xyzzy;
}

1;
