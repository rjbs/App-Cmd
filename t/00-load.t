#!perl

use Test::More tests => 5;

BEGIN {
  use_ok( 'App::Cmd' );
  use_ok( 'App::Cmd::Command' );
  use_ok( 'App::Cmd::Command::commands' );
  use_ok( 'App::Cmd::Subdispatch' );
  use_ok( 'App::Cmd::Subdispatch::DashedStyle' );
}

diag( "Testing App::Cmd $App::Cmd::VERSION" );
