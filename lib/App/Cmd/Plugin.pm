use strict;
use warnings;
package App::Cmd::Plugin;
# ABSTRACT: a plugin for App::Cmd commands

sub _faux_curried_method {
  my ($class, $name, $arg) = @_;

  return sub {
    my $cmd = $App::Cmd::active_cmd;
    $class->$name($cmd, @_);
  }
}

1;
