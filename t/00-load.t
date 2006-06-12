#!perl -T

use Test::More tests => 3;

BEGIN {
  use_ok( 'App::Cmd' );
  use_ok( 'App::Cmd::Command' );
  use_ok( 'App::Cmd::Command::commands' );
}

diag( "Testing App::Cmd $App::Cmd::VERSION" );
