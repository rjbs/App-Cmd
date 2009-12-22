use strict;
use warnings;

package Test::WithSetup;
use App::Cmd::Setup -app => {
  plugins => [ qw(=Test::XyzzyPlugin) ],
};

1;
