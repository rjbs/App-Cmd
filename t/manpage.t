#!perl
use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;

use lib 't/lib';

use Test::MyCmd;

subtest 'subcommand' => sub {
    my $return = test_app( 'Test::MyCmd', [qw(manpage --no-pager exit)] );

    my $stdout = $return->stdout;

    like( $stdout, qr/\S/, "manual page text was output", )
      or note $return->error;

    like(
        $stdout,
        qr/NAME\s+Test::MyCmd::Command::exit/,
        "NAME section was output",
    ) or note $return->error;

    like(
        $stdout,
        qr/DESCRIPTION\s+This package exists/,
        "DESCRIPTION section was output",
    ) or note $return->error;

};

subtest 'command' => sub {
    my $return = test_app( 'Test::MyCmd', [qw(manpage --no-pager)] );

    my $stdout = $return->stdout;

    like( $stdout, qr/\S/, "manual page text was output", )
      or note $return->error;

    like(
        $stdout,
        qr/NAME\s+manpage.t/,
        "NAME section was output",
    ) or note $return->error;

    like(
        $stdout,
        qr/DESCRIPTION\s+manpage test description/,
        "DESCRIPTION section was output",
    ) or note $return->error;

};

done_testing();

__END__

=head1 NAME

manpage.t

=head1 DESCRIPTION

manpage test description
