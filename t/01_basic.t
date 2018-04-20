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
    is $stderr[2], "1";
};

subtest code_rediret => sub {
    my (@stdout, @stderr);
    my $ret = Command::Runner->new
        ->command(sub { for (1..2) { warn "1\n"; print "2\n" } warn "1\n"; print 2; return 3 })
        ->redirect(1)
        ->on(stdout => sub { push @stdout, $_[0] })
        ->on(stderr => sub { push @stderr, $_[0] })
        ->run;
    is $ret, 3;
    is @stdout, 6;
    is @stderr, 0;
};

subtest array => sub {
    my ($stdout, $stderr) = ("", "");
    my $ret = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; exit 3'])
        ->on(stdout => sub { $stdout .= $_[0] })
        ->on(stderr => sub { $stderr .= $_[0] })
        ->run;
    is $ret >> 8, 3;
    is $stdout, "2";
    is $stderr, "1";
};

subtest array_redirect => sub {
    my ($stdout, $stderr) = ("", "");
    my $ret = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; exit 3'])
        ->redirect(1)
        ->on(stdout => sub { $stdout .= $_[0] })
        ->on(stderr => sub { $stderr .= $_[0] })
        ->run;
    is $ret >> 8, 3;
    is $stdout, "12";
    is $stderr, "";
};

subtest string => sub {
    my ($stdout, $stderr) = ("", "");
    my $command = qq{"$^X" "-e" "warn 1; print 2; exit 3"};
    my $ret = Command::Runner->new
        ->command($command)
        ->on(stdout => sub { $stdout .= $_[0] })
        ->on(stderr => sub { $stderr .= $_[0] })
        ->run;
    is $ret >> 8, 3;
    is $stdout, "2";
    is $stderr, "1 at -e line 1.";
};

subtest string_redirect => sub {
    my ($stdout, $stderr) = ("", "");
    my $command = qq{"$^X" "-e" "warn 1; print 2; exit 3"};
    my $ret = Command::Runner->new
        ->command($command)
        ->redirect(1)
        ->on(stdout => sub { $stdout .= $_[0] })
        ->run;
    is $ret >> 8, 3;
    is $stdout, "1 at -e line 1.2";
    is $stderr, "";
};

subtest timeout => sub {
    my ($stdout, $stderr) = ("", "");
    my ($ret, $is_timeout) = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; sleep 1'])
        ->timeout(0.5)
        ->on(stdout => sub { $stdout .= $_[0] })
        ->on(stderr => sub { $stderr .= $_[0] })
        ->run;
    ok $is_timeout;
    is $stdout, "2";
    is $stderr, "1";
};

done_testing;
