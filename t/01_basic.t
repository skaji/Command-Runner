use strict;
use warnings;
use Test::More;
use Command::Runner;

subtest code => sub {
    my (@stdout, @stderr);
    my $ret = Command::Runner->new
        ->command(sub { for (1..2) { warn "1\n"; print "2\n" } warn "1\n"; print 2; return 3 })
        ->on(stdout => sub { push @stdout, $_[0] })
        ->on(stderr => sub { push @stderr, $_[0] })
        ->run;
    is $ret, 3;
    is @stdout, 3;
    is @stderr, 3;
    is $stdout[2], "2";
    is $stderr[2], "1\n";
};

subtest array => sub {
    my ($stdout, $stderr) = ("", "");
    my $ret = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; exit 3'])
        ->on(stdout => sub { $stdout .= $_[0] })
        ->on(stderr => sub { $stderr .= $_[0] })
        ->run;
    is $ret >> 8, 3;
    is $stdout, "2\n";
    is $stderr, "1\n";
};

subtest string => sub {
    my ($stdout, $stderr) = ("", "");
    my $command = qq{"$^X" "-e" "print 2; exit 3"};
    my $ret = Command::Runner->new
        ->command($command)
        ->on(stdout => sub { $stdout .= $_[0] })
        ->on(stderr => sub { $stderr .= $_[0] })
        ->run;
    is $ret >> 8, 3;
    is $stdout, "2";
    is $stderr, "";
};

subtest timeout => sub {
    plan skip_all => 'timeout is not supported on Win32' if $^O eq 'MSWin32';
    my ($stdout, $stderr) = ("", "");
    my $timeout;
    my $ret = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; sleep 1'])
        ->timeout(0.5)
        ->on(timeout => sub { $timeout++ })
        ->on(stdout => sub { $stdout .= $_[0] })
        ->on(stderr => sub { $stderr .= $_[0] })
        ->run;
    ok $timeout;
    is $stdout, "2\n";
    is $stderr, "1\n";
};

done_testing;
