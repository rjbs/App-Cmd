#!perl

use strict;
use warnings;

use Test::More tests => 2;
use App::Cmd::Tester::CaptureExternal;

use lib 't/lib';

use Test::MyCmd;

my $app = Test::MyCmd->new;

isa_ok($app, 'Test::MyCmd');

my $return = test_app('Test::MyCmd', [ qw(hello) ]);

like( $return->output, qr/Hello World/, "Captured external subcommand output" );

