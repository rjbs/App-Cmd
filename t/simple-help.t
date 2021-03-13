#!perl
use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;

use lib 't/lib';

use Test::MySimple;

my $return = test_app('Test::MySimple', [ qw(--help) ]);

my $stdout = $return->stdout;

like(
    $stdout,
    qr/\S/,
    "Our simple app prints some help text.",
);

like(
    $stdout,
    qr/\[-f\]\s+\[long options\.\.\.\]/,
    "Our simple app prints a usage message",
);

{
  my @want = ('-f', '--fooble', 'check all foobs for foobling');
  my @lines = split /\n/, $stdout;

  my $got;
  for my $line (@lines) {
    index($line, $_) == -1 && next for @want;
    $got++;
  }

  ok($got, "there's a line in help fully describing --fooble");
}

unlike(
    $stdout,
    qr/commands/i,
    "Our simple app doesn't talk about subcommands",
);

done_testing()
