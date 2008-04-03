use strict;
use warnings;
package App::Cmd::Tester;

use Sub::Exporter::Util qw(curry_method);
use Sub::Exporter -setup => {
  exports => { test_app => curry_method },
  groups  => { default  => [ qw(test_app) ] },
};

sub test_app {
  my ($class, $app_class, $argv) = @_;

  my $combined = '';
  my $stdout = tie local *STDOUT, 'App::Cmd::Tester::Handle', \$combined;
  my $stderr = tie local *STDERR, 'App::Cmd::Tester::Handle', \$combined;

  my $rv;
  my $ok = eval {
    local @ARGV = @$argv;
    $rv = $app_class->run;
    1;
  };

  my $error = $ok ? undef : $@;

  return {
    stdout   => $stdout->output,
    stderr   => $stderr->output,
    combined => $combined,
    error    => $error,
    rv       => $rv,
  };
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

1;
