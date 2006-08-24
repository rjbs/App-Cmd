package Test::MyCmd2;

use strict;
use warnings;

use base qw(App::Cmd);

sub global_opt_spec {
  [ 'verbose+' => "Verbosity" ],
}

1;
