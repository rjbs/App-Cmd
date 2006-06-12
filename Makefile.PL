use strict;
use warnings;

use inc::Module::Install;

name          ('App-Cmd');
author        ('Ricardo SIGNES <rjbs@cpan.org>');
license       ('perl');
version_from  ('lib/App/Cmd.pm');

# fix these
# requires      ('Sub::Exporter' => 0.950);

WriteAll();
