use strict;
use warnings;

package App::Cmd::Subdispatch::DashedStyle;
use App::Cmd::Subdispatch;
BEGIN { our @ISA = 'App::Cmd::Subdispatch' };

# ABSTRACT: "app cmd --subcmd" style subdispatching

=method get_command

  my ($subcommand, $opt, $args) = $subdispatch->get_command(@args)

A version of get_command that chooses commands as options in the following
style:

  mytool mycommand --mysubcommand

=cut

sub get_command {
	my ($self, @args) = @_;

	my (undef, $opt, @sub_args)
    = $self->App::Cmd::Command::prepare($self->app, @args);

	if (my $cmd = delete $opt->{subcommand}) {
		delete $opt->{$cmd}; # useless boolean
		return ($cmd, $opt, @sub_args);
	} else {
    return (undef, $opt, @sub_args);
  }
}

=method opt_spec

A version of C<opt_spec> that calculates the getopt specification from the
subcommands.

=cut

sub opt_spec {
	my ($self, $app) = @_;

	my $subcommands = $self->_command;
	my %plugins = map {
		$_ => [ $_->command_names ],
	} values %$subcommands;

	foreach my $opt_spec (values %plugins) {
		$opt_spec = join("|", grep { /^\w/ } @$opt_spec);
	}

	my @subcommands = map { [ $plugins{$_} =>  $_->abstract ] } keys %plugins;

	return (
		[ subcommand => hidden => { one_of => \@subcommands } ],
		$self->global_opt_spec($app),
		{ getopt_conf => [ 'pass_through' ] },
	);
}

1;
