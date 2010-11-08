use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

use lib 't/lib';

ok( !exists $INC{'Test/BrokenCmd/Command.pm'},           'Broken library not tried to load yet' );
ok( !exists $INC{'Test/BrokenCmd/Command::Notthere.pm'}, 'Missing library not tried to load yet' );

isnt(
  exception {
    require Test::BrokenCmd;
  },
  undef,
  'using an obviously broken library should die'
);

isnt(
  exception {
    require Test::BrokenCmd::Command;
  },
  undef,
  'the broken library is broken'
);

ok( exists $INC{'Test/BrokenCmd/Command.pm'},            'Broken library tried to load' );
ok( !exists $INC{'Test/BrokenCmd/Command::Notthere.pm'}, 'Missing library not tried to load yet' );

done_testing;
