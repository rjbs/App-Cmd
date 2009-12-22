use strict;
use warnings;

# WSOF: with Setup, one file
package Test::WSOF;
use App::Cmd::Setup -app => {
  plugins => [ qw(=Test::XyzzyPlugin) ],
};

package Test::WSOF::Command::poot;
use Test::WSOF -command;

sub execute { return 'woof woof poot' }

1;
