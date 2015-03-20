#!perl

use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;

use lib 't/lib';

use Test::MyCmd;

{
  my $app = Test::MyCmd->new({ show_version_cmd => 1 });
  my $ret = App::Cmd::Tester->_run_with_capture( $app , [ 'commands' ]);

  like( $ret->{output} , qr/version/ , 'see version in output');
  is( $ret->{error} , undef , 'no errors' );
}
{
  my $app = Test::MyCmd->new({ show_version_cmd => 0 });
  my $ret = App::Cmd::Tester->_run_with_capture( $app , [ 'commands' ]);

  unlike( $ret->{output} , qr/version/ , 'do not see version in output');
  is( $ret->{error} , undef , 'no errors' );
}

done_testing;
