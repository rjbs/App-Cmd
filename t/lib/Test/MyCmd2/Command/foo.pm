package Test::MyCmd2::Command::foo;
use base qw/App::Cmd::Subdispatch/;

use constant plugin_search_path => __PACKAGE__;

use constant global_opt_spec => (
  [ 'moose' => "lefoo" ],
);

1;
