use strict;
use warnings;

package Test::WithSetup;
use App::Cmd::Setup -app => {
  getopt_conf => [],
  plugins => [ qw(=Test::XyzzyPlugin) ],
};

1;
