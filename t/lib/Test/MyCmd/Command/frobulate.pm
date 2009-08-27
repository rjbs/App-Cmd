package Test::MyCmd::Command::frobulate;

use strict;
use warnings;

use base qw(App::Cmd::Command);

sub command_names {
  return qw(frobulate frob);
}

sub opt_spec {
  return (
    [ "foo-bar|F", "enable foo-bar subsystem" ],
    [ "widget=s",  "set widget name"          ],
  );
}

sub execute {
  my ($self, $opt, $arg) =@_;

  die "the widget name is $opt->{widget} - @$arg\n";
}

1;
