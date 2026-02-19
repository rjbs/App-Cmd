use strict;
use warnings;

package App::Cmd::Command::commands;

use App::Cmd::Command;
BEGIN { our @ISA = 'App::Cmd::Command' };

# ABSTRACT: list the application's commands

=head1 DESCRIPTION

This command will list all of the application commands available and their
abstracts.

=method execute

This is the command's primary method and raison d'etre.  It prints the
application's usage text (if any) followed by a sorted listing of the
application's commands and their abstracts.

The commands are printed in sorted groups (created by C<sort_commands>); each
group is set off by blank lines.

=cut

sub opt_spec {
  return (
    [ 'stderr' => 'hidden' ],
    [ 'for-completion',   'one per line, for use in tab completion scripts' ],
    [ 'bash-completion',  'output a bash completion script for this application' ],
    [ 'zsh-completion',   'output a zsh completion script for this application' ],
  );
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $target = $opt->stderr ? *STDERR : *STDOUT;

  my @cmd_groups = $self->app->command_groups;
  my @primary_commands = map { @$_ if ref $_ } @cmd_groups;

  if (!@cmd_groups) {
    @primary_commands =
      grep { $_ ne 'version' or $self->app->{show_version} }
      map { ($_->command_names)[0] }
      $self->app->command_plugins;

    @cmd_groups = $self->sort_commands(@primary_commands);
  }

  if ($opt->for_completion) {
    print "$_\n" for map {; @$_ } @cmd_groups;
    return;
  }

  if ($opt->bash_completion) {
    $self->_print_bash_completion(\@cmd_groups);
    return;
  }

  if ($opt->zsh_completion) {
    $self->_print_zsh_completion(\@cmd_groups);
    return;
  }

  my $fmt_width = 0;
  for (@primary_commands) { $fmt_width = length if length > $fmt_width }
  $fmt_width += 2; # pretty

  foreach my $cmd_set (@cmd_groups) {
    if (!ref $cmd_set) {
      print { $target } "$cmd_set:\n";
      next;
    }
    for my $command (@$cmd_set) {
      my $abstract = $self->app->plugin_for($command)->abstract;
      printf { $target } "%${fmt_width}s: %s\n", $command, $abstract;
    }
    print { $target } "\n";
  }
}

=method C<sort_commands>

  my @sorted = $cmd->sort_commands(@unsorted);

This method orders the list of commands into groups which it returns as a list of
arrayrefs, and optional group header strings.

By default, the first group is for the "help" and "commands" commands, and all
other commands are in the second group.

This method can be overridden by implementing the C<commands_groups> method in
your application base clase.

=cut

sub _print_bash_completion {
  my ($self, $cmd_groups) = @_;

  die "--bash-completion requires a version of Getopt::Long::Descriptive "
    . "that supports shell completion generation\n"
    unless Getopt::Long::Descriptive->can('_completion_for_bash');

  my $app  = $self->app;
  my $prog = $app->arg0;
  (my $func = "_${prog}_complete") =~ s/\W/_/g;

  my @all_cmds = map {; @$_ } @$cmd_groups;

  my %cmd_completion;
  for my $cmd (@all_cmds) {
    my $plugin = $app->plugin_for($cmd) or next;
    $cmd_completion{$cmd} =
      Getopt::Long::Descriptive::_completion_for_bash($plugin->opt_spec);
  }

  my $cmds_str = join q{ }, @all_cmds;

  print <<"END_HEADER";
$func() {
    local cur prev words cword
    _init_completion 2>/dev/null || {
        cur="\${COMP_WORDS[COMP_CWORD]}"
        prev="\${COMP_WORDS[COMP_CWORD-1]}"
    }
    words=("\${COMP_WORDS[\@]}")
    cword=\$COMP_CWORD

    local cmd=""
    local i
    for ((i=1; i < cword; i++)); do
        if [[ "\${words[i]}" != -* ]]; then
            cmd="\${words[i]}"
            break
        fi
    done

    if [[ -z "\$cmd" ]]; then
        COMPREPLY=(\$(compgen -W "$cmds_str" -- "\$cur"))
        return
    fi

    case "\$cmd" in
END_HEADER

  for my $cmd (sort keys %cmd_completion) {
    my $completion = $cmd_completion{$cmd};
    my $flags_str = $completion->{flags};

    next unless $flags_str || @{ $completion->{prev_cases} };

    print "        $cmd)\n";

    if (@{ $completion->{prev_cases} }) {
      print "            case \"\$prev\" in\n";
      for my $case (@{ $completion->{prev_cases} }) {
        print "                $case->{pattern})\n";
        print "                    $case->{action}\n";
        print "                    return ;;\n";
      }
      print "            esac\n";
    }

    print "            COMPREPLY=(\$(compgen -W \"$flags_str\" -- \"\$cur\"))\n";
    print "            ;;\n";
  }

  print <<"END_FOOTER";
        *)
            COMPREPLY=()
            ;;
    esac
}
complete -F $func $prog
END_FOOTER
}

sub _print_zsh_completion {
  my ($self, $cmd_groups) = @_;

  die "--zsh-completion requires a version of Getopt::Long::Descriptive "
    . "that supports shell completion generation\n"
    unless Getopt::Long::Descriptive->can('_completion_for_zsh');

  my $app  = $self->app;
  my $prog = $app->arg0;
  (my $func = "_${prog}_complete") =~ s/\W/_/g;

  my @all_cmds = map {; @$_ } @$cmd_groups;

  my @cmd_descs;
  my %cmd_zsh_args;
  for my $cmd (@all_cmds) {
    my $plugin = $app->plugin_for($cmd) or next;
    (my $abstract = $plugin->abstract) =~ s/'/'\\''/g;
    push @cmd_descs, "        '$cmd:$abstract'";
    $cmd_zsh_args{$cmd} = [ Getopt::Long::Descriptive::_completion_for_zsh($plugin->opt_spec) ];
  }

  my $cmd_list = join "\n", @cmd_descs;

  print <<"END_HEADER";
#compdef $prog

$func() {
    local curcontext="\$curcontext" state line
    typeset -A opt_args

    _arguments -C \\
        '1: :->command' \\
        '*:: :->args'

    case \$state in
        command)
            local -a _cmds
            _cmds=(
$cmd_list
            )
            _describe 'command' _cmds
            ;;
        args)
            case \$line[1] in
END_HEADER

  for my $cmd (sort keys %cmd_zsh_args) {
    my @args = @{ $cmd_zsh_args{$cmd} };
    print "                $cmd)\n";
    if (@args) {
      print "                    _arguments \\\n";
      for my $i (0 .. $#args) {
        my $cont = $i < $#args ? ' \\' : '';
        print "                        $args[$i]$cont\n";
      }
    } else {
      print "                    _arguments\n";
    }
    print "                    ;;\n";
  }

  print <<"END_FOOTER";
                *)
                    ;;
            esac
            ;;
    esac
}
$func "\$\@"
END_FOOTER
}

sub sort_commands {
  my ($self, @commands) = @_;

  my $float = qr/^(?:help|commands)$/;

  my @head = sort grep { $_ =~ $float } @commands;
  my @tail = sort grep { $_ !~ $float } @commands;

  return (\@head, \@tail);
}

1;
