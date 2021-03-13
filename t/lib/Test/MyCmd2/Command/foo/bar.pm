package Test::MyCmd2::Command::foo::bar;
use parent qw/App::Cmd::Command/;

use constant opt_spec => (
  [ foo => "lefoo" ],
);

1;

