package Test::WithCallback::Command::lol;
use strict;
use Test::WithCallback -command;

sub opt_spec {
    return (
        [ "even|e=s", "an even number", {
            callbacks => {
                valid_email => sub { return !($_[0] % 2) }
            }
        }],
    );
}

sub execute {
    print 'yay';
}

1;
