#!perl
use strict;
use warnings;

use App::Cmd::Tester;

my ($exit_with) = @ARGV;
print "$INC{'App/Cmd/Tester.pm'}\n";

exit $exit_with; # nb. the App::Cmd::Tester one
