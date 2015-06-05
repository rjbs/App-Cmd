#!perl
use strict;
use warnings;

use Test::More tests => 3;
use Capture::Tiny 'capture';

require App::Cmd::Tester; # not used, but check which!

my $helper_fn = $0;
$helper_fn =~ s{\.t$}{.helper.pl} or die "Can't make helper from $0";

for my $exit_with (0, 5) {
  my ($stdout, $stderr, $got_exit) = capture {
    system($^X, $helper_fn, $exit_with);
  };

  chomp $stdout;
  is($INC{'App/Cmd/Tester.pm'}, $stdout, "App::Cmd::Tester source path")
    unless $exit_with; # just once

  is($exit_with,
     $got_exit / 256, # yes it could be fractional, and that would be fail
     "exit code as expected");
}
