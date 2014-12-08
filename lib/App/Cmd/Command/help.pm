use strict;
use warnings;

package App::Cmd::Command::help;

use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command'; }

# ABSTRACT: display a command's help screen

=head1 DESCRIPTION

This command plugin implements a "help" command.  This command will either list
all of an App::Cmd's commands and their abstracts, or display the usage screen
for a subcommand with its description.

=head1 USAGE

The help text is generated from three sources:

=for :list
* The C<usage_desc> method
* The C<description> method
* The C<opt_spec> data structure

The C<usage_desc> method provides the opening usage line, following the
specification described in L<Getopt::Long::Descriptive>.  In some cases,
the default C<usage_desc> in L<App::Cmd::Command> may be sufficient and
you will only need to override it to provide additional command line
usage information.

The C<opt_spec> data structure is used with L<Getopt::Long::Descriptive>
to generate the description of the options.

Subcommand classes should override the C<discription> method to provide
additional information that is prepended before the option descriptions.

For example, consider the following subcommand module:

  package YourApp::Command::initialize;

  # This is the default from App::Cmd::Command
  sub usage_desc {
    my ($self) = @_;
    my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
    return "$desc [DIRECTORY]";
  }

  sub description {
    return "The initialize command prepares the application...";
  }

  sub opt_spec {
    return (
      [ "skip-refs|R",  "skip reference checks during init", ],
      [ "values|v=s@",  "starting values", { default => [ 0, 1, 3 ] } ],
    );
  }

  ...

That module would generate help output like this:

  $ yourapp help initialize
  yourapp initialize [-Rv] [long options...] [DIRECTORY]

  The initialize command prepares the application...

        --help            This usage screen
        -R --skip-refs    skip reference checks during init
        -v --values       starting values

=cut

sub usage_desc { '%c help [subcommand]' }

sub command_names { qw/help --help -h -?/ }

sub description {
"This command will either list all of the application commands and their
abstracts, or display the usage screen for a subcommand with its
description.\n"
}

sub execute {
  my ($self, $opts, $args) = @_;

  if (!@$args) {
    print $self->app->usage->text . "\n";

    print "Available commands:\n\n";

    $self->app->execute_command( $self->app->_prepare_command("commands") );
  } else {
    my ($cmd, $opt, $args) = $self->app->prepare_command(@$args);

    local $@;
    my $desc = $cmd->description;
    $desc = "\n$desc" if length $desc;

    my $ut = join "\n",
      eval { $cmd->usage->leader_text },
      $desc,
      eval { $cmd->usage->option_text };

    print "$ut\n";
  }
}

1;
