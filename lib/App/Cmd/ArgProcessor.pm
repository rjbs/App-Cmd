use strict;
use warnings;

package App::Cmd::ArgProcessor;

=head1 NAME

App::Cmd::ArgProcessor - App::Cmd-specific wrapper for Getopt::Long::Descriptive

=head1 VERSION

version 0.014_02

=cut

our $VERSION = '0.014_02';

sub _process_args {
  my ($class, $args, @params) = @_;
  local @ARGV = @$args;

  require Getopt::Long::Descriptive;

  my ($opt, $usage) = Getopt::Long::Descriptive::describe_options(@params);

  return (
    $opt,
    [ @ARGV ], # whatever remained
    usage => $usage,
  );
}

1;
