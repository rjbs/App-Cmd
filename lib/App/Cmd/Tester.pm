use strict;
use warnings;
package App::Cmd::Tester;

=head1 NAME

App::Cmd::Tester - for capturing the result of running an app

=head1 SYNOPSIS

  use Test::More tests => 4;
  use App::Cmd::Tester;

  use YourApp;

  my $result = test_app(YourApp => [ qw(command --opt value) ]);

  like($result->stdout, qr/expected output/, 'printed what we expected');

  is($result->stderr, '', 'nothing sent to sderr');

  is($result->error, undef, 'threw no exceptions');

  my $result = test_app(YourApp => [ qw(command --opt value --quiet) ]);

  is($result->output, '', 'absolutely no output with --quiet');

=head1 DESCRIPTION

One of the reasons that user-executed programs are so often poorly tested is
that they are hard to test.  App::Cmd::Tester is one of the tools App-Cmd
provides to help make it easy to test App::Cmd-based programs.

It provides one routine: test_app.

=head1 METHODS

=head2 test_app

B<Note>: while C<test_app> is a method, it is by default exported as a
subroutine into the namespace that uses App::Cmd::Tester.  In other words: you
probably don't need to think about this as a method unless you want to subclass
App::Cmd::Tester.

  my $result = test_app($app_class => \@argv_contents);

This will locally set C<@ARGV> to simulate command line arguments, and will
then call the C<run> method on the given application class (or application).
Output to the standard output and standard error filehandles  will be captured.

C<$result> is an App::Cmd::Tester::Result object, which has methods to access
the following data:

  stdout - the output sent to stdout
  stderr - the output sent to stderr
  output - the combined output of stdout and stderr
  error  - the exception thrown by running the application, or undef
  run_rv - the return value of the run method (generally irrelevant)

=cut

use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
  exports => { test_app => curry_method },
  groups  => { default  => [ qw(test_app) ] },
};

sub test_app {
  my ($class, $app, $argv) = @_;

  my $combined = '';
  my $stdout = tie local *STDOUT, 'App::Cmd::Tester::Handle', \$combined;
  my $stderr = tie local *STDERR, 'App::Cmd::Tester::Handle', \$combined;

  my $run_rv;
  my $ok = eval {
    local @ARGV = @$argv;
    $run_rv = $app->run;
    1;
  };

  my $error = $ok ? undef : $@;

  bless {
    stdout => $stdout->output,
    stderr => $stderr->output,
    output => $combined,
    error  => $error,
    run_rv => $run_rv,
  } => 'App::Cmd::Tester::Result';
}

{
  package App::Cmd::Tester::Result;
  for my $attr (qw(stdout stderr output error run_rv)) {
    Sub::Install::install_sub({
      code => sub { $_[0]->{$attr} },
      as   => $attr,
    });
  }
}

{
  package App::Cmd::Tester::Handle;
  sub TIEHANDLE {
    my ($class, $combined_ref) = @_;

    my $guts = {
      output       => '',
      combined_ref => $combined_ref,
    };

    return bless $guts => $class;
  }

  sub PRINT {
    my ($self, @output) = @_;

    my $joined = join((defined $, ? $, : ''), @output);
    $self->{output}            .= $joined;
    ${ $self->{combined_ref} } .= $joined;

    return 1;
  }

  sub PRINTF {
    my $self = shift;
    my $fmt  = shift;
    $self->PRINT(sprintf($fmt, @_));
  }

  sub FILENO   {}
  sub output   { $_[0]->{output} }
  sub combined { ${ $_[0]->{combined_ref} } }
}

=head1 AUTHOR AND COPYRIGHT

Copyright 2008, (code (simply)).  All rights reserved;  App::Cmd and bundled
code are free software, released under the same terms as perl itself.

=cut

1;
