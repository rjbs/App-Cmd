package App::Cmd::Command::manpage;

use strict;
use warnings;

use App::Cmd -command;
use Pod::Find qw[ pod_where ];
use Pod::Usage qw[ pod2usage ];
use File::Spec::Functions qw[ catdir ];

# ABSTRACT: display a command's manual page

=head1 DESCRIPTION

This command will display a manual page for a command based upon POD
embedded in the command's source.  If no POD is available, it will
fail with an error.

=head1 USAGE

The manual text is generated using L<Pod::Usage/pod2usage> with
a verbosity level of C<2> and an exit value of C<0>.

=cut

sub usage_desc { '%c manpage %o [subcommand]' }

sub opt_spec { [ 'no-pager' => "don't page output", { default => 0 } ] }

sub command_names { qw/manpage man --man --manpage/ }

sub abstract { "display the application's manual page or that of a particular command" }

sub description { "display the application's manual page or that of a particular command" }

sub execute {
    my ( $self, $opts, $args ) = @_;

    my @usage_args;

    if ( !@$args ) {
        require FindBin;
        push @usage_args, -input => catdir( $FindBin::RealBin, $FindBin::RealScript );
    }
    else {

        my $plugin;
        unless ( $plugin = $self->app->plugin_for( $args->[0] ) ) {
            $self->app->execute_command(
                $self->app->_bad_command( $args->[0], $opts, $args ) );
            exit 1;
        }

        my $file;
        unless ( $file = pod_where( { -inc => 1 }, $plugin ) ) {
            print STDERR "No documentation for command '$args->[0]'\n";
            exit 1;
        }

        push @usage_args, -input => $file;
    }

    pod2usage(
        -exitval   => 0,
        -verbose   => 2,
        -noperldoc => $opts->no_pager,
        @usage_args
    );

}

1;



