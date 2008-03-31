use strict;
use warnings;
package Test::XyzzyPlugin;
use App::Cmd::Setup -plugin => {
  exports => [ qw(xyzzy) ],
};

sub xyzzy {
  my ($cmd, @arg) = @_;

  return [ $cmd, \@arg ];
}

1;
