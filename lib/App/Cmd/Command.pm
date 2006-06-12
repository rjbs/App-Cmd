package Rubric::CLI::Command;

=head1 NAME

Rubric::CLI::Command - a base class for rubric commands

=head1 VERSION

 $Id$

=cut

use strict;
use warnings;

use Carp ();
use Getopt::Long::Descriptive ();

=head1 METHODS

=head2 C< run >

This method does whatever it is the command should do!

=cut

sub run {
  my ($class) = @_;
  Carp::croak "$class does not implement mandatory method 'run'\n";
}

sub app { $_[0]->{app}; }
sub usage { local $SIG{__DIE__} = sub { Carp::confess @_ };$_[0]->{usage}; }

sub usage_desc {
  my ($self) = @_;
  my $moniker = $self->moniker;
  return "%c $moniker %o"
}

sub opt_spec {
  return;
}

sub new {
  my ($class, $arg) = @_;
  bless $arg => $class;
}

sub validate_args {}

1;
