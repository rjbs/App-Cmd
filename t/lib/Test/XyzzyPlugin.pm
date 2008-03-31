use strict;
use warnings;
package Test::XyzzyPlugin;
use App::Cmd::Setup -plugin => {
  exports => [ qw(xyzzy) ],
};

sub xyzzy {
  my ($self, $cmd, @arg) = @_;

  return [ $self, $cmd, \@arg ];
}

1;
