package Test::MyCmd2;

use strict;
use warnings;

use parent qw(App::Cmd);

sub global_opt_spec {
  [ 'verbose+' => "Verbosity" ],
}

1;
