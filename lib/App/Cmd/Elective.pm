use strict;
use warnings;

package App::Cmd::Elective;

# ABSTRACT: load only ::Command::* from a whitelist

use parent 'App::Cmd::Setup';

require App::Cmd::Base::Elective;

sub _app_base_class { 'App::Cmd::Base::Elective' }

=head1 SYNOPSIS

If you have an existing App which uses App::Cmd and you want to add whitelist only
support, a simple change is required:

    diff:

    -use App::Cmd::Setup -app
    +use App::Cmd::Elective -app

    +sub app_commands {
    +   qw( foo bar )
    +}

The function C<app_commands> returns a list of commandlets to load. ( In additional to any defaults provided by App::Cmd ).

Note: Note these are B<NOT> nessecarily the same as the CLI command names, but these are the "providing module" names, which are expanded based upon the value of L<< C<plugin_search_path>|App::Cmd/plugin_search_path >>, and then the resulting command name is based on the individual modules values of L<< C<command_names>|App::Cmd::Command/command_names >>

Otherwise, except for this minor difference, usage should be identical to that of App::Cmd's standard behaviour

=cut

1;
