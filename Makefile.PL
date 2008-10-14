use inc::Module::Install;

all_from('lib/App/Cmd.pm');

requires('Getopt::Long::Descriptive' => 0.06); # numerous bug fixes
requires('Module::Pluggable::Object' => 0.00);
requires('Sub::Exporter'             => 0.975); # curry_method
requires('Sub::Install'              => 0.00); # minimum unknown

extra_tests;

WriteAll();
