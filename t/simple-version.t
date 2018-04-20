#!perl
use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;

use lib 't/lib';

use Test::MySimple;

our $VERSION = '0.123';

my $return = test_app('Test::MySimple', [ qw(--version) ]);

my $stdout = $return->stdout;

like(
    $stdout,
    qr/\S/,
    "Our simple app prints out some version information.",
);

is(
    $stdout,
    "simple-version.t (Test::MySimple::_App_Cmd::0) version $VERSION (t/simple-version.t)\n",
    "Our simple app prints out correct version information",
);


done_testing()
