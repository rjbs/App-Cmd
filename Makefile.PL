use strict;
use warnings;

use inc::Module::Install;

name          ('App-Cmd');
author        ('Ricardo SIGNES <rjbs@cpan.org>');
license       ('perl');
version_from  ('lib/App/Cmd.pm');

requires      ('Getopt::Long::Descriptive' => 0.04);
requires      ('Module::Pluggable::Object' => 0.00);

WriteAll();
