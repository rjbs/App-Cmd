use strict;
use warnings;
package App::Cmd::Tester;

# ABSTRACT: for capturing the result of running an app

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

=method test_app

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
  exit_code - the numeric exit code that would've been issued (0 is 'okay')

=cut

use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
  exports => { test_app => curry_method },
  groups  => { default  => [ qw(test_app) ] },
};

our $TEST_IN_PROGRESS;
BEGIN {
  *CORE::GLOBAL::exit = sub {
    return CORE::exit(@_) unless $TEST_IN_PROGRESS;
    App::Cmd::Tester::Exited->throw($_[0]);
  };
}

=for Pod::Coverage result_class

=cut

sub result_class { 'App::Cmd::Tester::Result' }

sub test_app {
  my ($class, $app, $argv) = @_;

  local $App::Cmd::_bad = 0;

  $app = $app->new unless ref($app) or $app->isa('App::Cmd::Simple');

  my $result = $class->_run_with_capture($app, $argv);

  my $error = $result->{error};

  my $exit_code = defined $error ? ((0+$!)||-1) : 0;

  if ($error and eval { $error->isa('App::Cmd::Tester::Exited') }) {
    $exit_code = $$error;
  }

  $exit_code =1 if $App::Cmd::_bad && ! $exit_code;

  $class->result_class->new({
    app    => $app,
    exit_code => $exit_code,
    %$result,
  });
}

sub _run_with_capture {
  my ($class, $app, $argv) = @_;

  require IO::TieCombine;
  my $hub = IO::TieCombine->new;

  my $stdout = tie local *STDOUT, $hub, 'stdout';
  my $stderr = tie local *STDERR, $hub, 'stderr';

  my $run_rv;

  my $ok = eval {
    local $TEST_IN_PROGRESS = 1;
    local @ARGV = @$argv;
    $run_rv = $app->run;
    1;
  };

  my $error = $ok ? undef : $@;

  return {
    stdout => $hub->slot_contents('stdout'),
    stderr => $hub->slot_contents('stderr'),
    output => $hub->combined_contents,
    error  => $error,
    run_rv => $run_rv,
  };
}

{
  package App::Cmd::Tester::Result;

  sub new {
    my ($class, $arg) = @_;
    bless $arg => $class;
  }

  for my $attr (qw(app stdout stderr output error run_rv exit_code)) {
    Sub::Install::install_sub({
      code => sub { $_[0]->{$attr} },
      as   => $attr,
    });
  }
}

{
  package App::Cmd::Tester::Exited;
  sub throw {
    my ($class, $code) = @_;
    $code = 0 unless defined $code;
    my $self = (bless \$code => $class);
    die $self;
  }
}

1;
