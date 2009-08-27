use strict;
use warnings;
package Test::WSNCC::Command::blort;
use Test::WSNCC -command;

sub execute {
  my ($self, $opt, $args) = @_;
  return $opt;
}

1;
