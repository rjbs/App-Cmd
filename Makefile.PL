use inc::Module::Install;

all_from('lib/App/Cmd.pm');

requires('Getopt::Long::Descriptive' => 0.081); # leader_text, option_text
requires('Module::Pluggable::Object' => 0.00);
requires('Sub::Exporter'             => 0.975); # curry_method
requires('Sub::Install'              => 0.00);  # minimum unknown
requires('String::RewritePrefix'     => 0.00);  # minimum unknown

test_requires('IO::TieCombine'       => 1.000); # first release

extra_tests;

repository('http://github.com/rjbs/app-cmd');
auto_manifest;

WriteAll();
