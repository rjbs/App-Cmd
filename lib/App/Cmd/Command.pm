package App::Cmd::Command;

=head1 NAME

App::Cmd::Command - a base class for App::Cmd commands

=head1 VERSION

 $Id$

=cut

use strict;
use warnings;

use Carp ();

=head1 METHODS

=head2 C< run >

This method does whatever it is the command should do!

=cut

sub run {
  my ($class) = @_;
  Carp::croak "$class does not implement mandatory method 'run'\n";
}

sub app { $_[0]->{app}; }
sub usage { $_[0]->{usage}; }

sub command_names {
  # from UNIVERSAL::moniker
  (ref( $_[0] ) || $_[0]) =~ /([^:]+)$/;
  return lc $1;
}

sub usage_desc {
  my ($self) = @_;
  my ($command) = $self->command_names;
  return "%c $command %o"
}

sub opt_spec {
  return;
}

sub new {
  my ($class, $arg) = @_;
  bless $arg => $class;
}

sub validate_args {}

# stolen from ExtUtils::MakeMaker
sub abstract {
  my ($class) = @_;
  $class = ref $class if ref $class;

  my $result;

  (my $pm_file = $class) =~ s!::!/!g;
  $pm_file .= '.pm';
  $pm_file = $INC{$pm_file};
  open my $fh, "<", $pm_file or return "(unknown)";

  local $/ = "\n";
  my $inpod = 0;
  while (<$fh>) {
    $inpod = /^=(?!cut)/ ? 1
           : /^=cut/     ? 0
           :               $inpod;
    next unless $inpod;
    chomp;
    next unless /^($class\s-\s)(.*)/;
    $result = $2;
    last;
  }
  return $result || "(unknown)";
}

1;
