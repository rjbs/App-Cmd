#!perl
use strict;
use warnings;

use Test::More tests => 1;
use App::Cmd::Tester;

use lib 't/lib';

use Test::MySimple;

my $return = test_app('Test::MySimple', [ ]);
my $error  = $return->error;

like(
  $error,
  qr/^Error: not enough args/,
  "our simple app fails without args",
);
