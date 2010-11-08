use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use lib 't/lib';

isnt( exception {
    require Test::BrokenCmd;
}, undef, 'using an obviously broken library should die' );

isnt( exception {
    require Test::BrokenCmd::Command;
}, undef, 'the broken library is broken' );


