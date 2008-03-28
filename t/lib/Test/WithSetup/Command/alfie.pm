use strict;
use warnings;
package Test::WithSetup::Command::alfie;
use Test::WithSetup -command;

sub run {
  my ($self, $opt, $args) = @_;
  return $opt;
}

1;
