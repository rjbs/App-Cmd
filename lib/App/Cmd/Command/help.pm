use strict;
use warnings;

package App::Cmd::Command::help;
use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command'; }

=head1 NAME

App::Cmd::Command::help - display a command's help screen

=head1 VERSION

version 0.014_01

=cut

our $VERSION = '0.014_01';

=head1 DESCRIPTION

This command plugin implements a "help" command.  This command will either list
all of an App::Cmd's commands and their abstracts, or display the usage screen
for a subcommand.

=cut


sub command_names { qw/help --help -h -?/ }

sub run {
  my ($self, $opts, $args) = @_;

  if (!@$args) {
    my $usage = $self->app->usage->text;
    my $command = $0;

    # chars normally used to describe options
    my $opt_descriptor_chars = qr/[\[\]<>\(\)]/;

    if ($usage =~ /^(.+?) \s* (?: $opt_descriptor_chars | $ )/x) {
      # try to match subdispatchers too
      $command = $1;
    }
    
    # evil hack ;-)
    bless
      $self->app->{usage} = sub { return "$command help <command>\n" }
      => "Getopt::Long::Descriptive::Usage";

    $self->app->execute_command( $self->app->_prepare_command("commands") );
  } else {
    my ($cmd, $opt, $args) = $self->app->prepare_command(@$args);
    print $cmd->_usage_text;
  }
}

1;
