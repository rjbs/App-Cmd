#!perl

use strict;
use warnings;

use Test::More tests => 1;
use App::Cmd::Tester;

use lib 't/lib';

use Test::MyCmdAbbrev;

my $app = Test::MyCmdAbbrev->new( {
    no_commands_plugin => 1,
    no_help_plugin     => 1,
    no_version_plugin  => 1,
} );

is_deeply(
    [ sort $app->command_names ],
    [ sort qw{ foo fo f bar baz } ],
    "got correct list of abbreviated registered command names",
);
