use strict;
use warnings;
use Test::More;
use Command::Runner;
use File::Temp ();
use Test::Needs 'Win32::ShellQuote';
use Test::Needs 'String::ShellQuote';

my $windows = $^O eq 'MSWin32';

subtest basic => sub {
    my @command = ($^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2');

    my @test;
    if ($windows) {
        push @test, Win32::ShellQuote::quote_system(@command);
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 };
    } else {
        push @test, \@command;
        push @test, String::ShellQuote::shell_quote_best_effort(@command);
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 };

    }
    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test);
        my @stdout; $cmd->on(stdout => sub { push @stdout, @_ });
        my @stderr; $cmd->on(stderr => sub { push @stderr, @_ });
        my ($exit, $is_timeout) = $cmd->run;
        is $exit, 0;
        ok !$is_timeout;
        is @stdout, 2;
        is @stderr, 2;
    }
};

subtest timeout => sub {
    my @command = ($^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2');

    my @test;
    if ($windows) {
        push @test, Win32::ShellQuote::quote_system(@command);
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2; return 0 };
    } else {
        push @test, \@command;
        push @test, String::ShellQuote::shell_quote_best_effort(@command);
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2; return 0 };

    }
    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test, timeout => 1);
        my @stdout; $cmd->on(stdout => sub { push @stdout, @_ });
        my @stderr; $cmd->on(stderr => sub { push @stderr, @_ });
        my ($exit, $is_timeout) = $cmd->run;
        ok $is_timeout;
        is $exit, 15 if !$windows && (ref $test ne 'CODE'); # SIGTERM
        is @stdout, 2;
        is @stderr, 2;
    }
};

done_testing;
