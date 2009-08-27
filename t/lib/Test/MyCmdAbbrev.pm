package Test::MyCmdAbbrev;

use strict;
use warnings;

use base qw{ App::Cmd };

sub allow_any_unambiguous_abbrev { 1 }

1;
