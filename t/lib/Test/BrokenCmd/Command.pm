use strict;
use warnings;

package Test::BrokenCmd::Command;

use App::Cmd::Setup -command;

die "BROKEN";

1;
