use strict;
use warnings;

package Test::WSNCC;
use App::Cmd::Setup -app => {
  plugins => [ qw(=Test::XyzzyPlugin) ],
};

1;
