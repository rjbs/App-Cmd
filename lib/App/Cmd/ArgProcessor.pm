use strict;
use warnings;

package App::Cmd::ArgProcessor;

# ABSTRACT: App::Cmd-specific wrapper for Getopt::Long::Descriptive

sub _process_args {
  my ($class, $args, @params) = @_;
  local @ARGV = @$args;

  require Getopt::Long::Descriptive;
  Getopt::Long::Descriptive->VERSION(0.116)
    if Getopt::Long::Descriptive->VERSION;

  my ($opt, $usage) = Getopt::Long::Descriptive::describe_options(@params);

  return (
    $opt,
    [ @ARGV ], # whatever remained
    usage => $usage,
  );
}

1;
