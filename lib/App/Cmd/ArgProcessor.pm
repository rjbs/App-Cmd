package App::Cmd::ArgProcessor;

=head1 NAME

App::Cmd::ArgProcessor - An L<App::Cmd> specific wrapper for
L<Getopt::Long::Descriptive>.

=head1 VERSION

 $Id: $

=cut

use strict;
use warnings;

sub _process_args {
  my ( $class, $args, @params ) = @_;
  local @ARGV = @$args;

  require Getopt::Long::Descriptive;

  my ( $opt, $usage ) = Getopt::Long::Descriptive::describe_options( @params );

  return (
    $opt,
    [@ARGV], # whatever remained
    usage => $usage,
  );
}

1;
