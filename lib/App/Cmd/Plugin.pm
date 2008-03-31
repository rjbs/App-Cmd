use strict;
use warnings;
package App::Cmd::Plugin;

sub _faux_curried_method {
  my ($class, $name, $arg) = @_;

  return sub {
    my $cmd = $App::Cmd::active_cmd;
    $class->$name($cmd, @_);
  }
}

1;
