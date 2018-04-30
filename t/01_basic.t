use strict;
use warnings;
use Test::More;
use Command::Runner;

my $windows = $^O eq 'MSWin32';

subtest code => sub {
    my (@stdout, @stderr);
    my $res = Command::Runner->new
        ->command(sub { for (1..2) { warn "1\n"; print "2\n" } warn "1\n"; print 2; return 3 })
        ->stdout(sub { push @stdout, $_[0] })
        ->stderr(sub { push @stderr, $_[0] })
        ->run;
    is $res->{result}, 3;
    is @stdout, 3;
    is @stderr, 3;
    is $stdout[2], "2";
    is $stderr[2], "1";
};

subtest code_rediret => sub {
    my (@stdout, @stderr);
    my $res = Command::Runner->new
        ->command(sub { for (1..2) { warn "1\n"; print "2\n" } warn "1\n"; print 2; return 3 })
        ->redirect(1)
        ->stdout(sub { push @stdout, $_[0] })
        ->stderr(sub { push @stderr, $_[0] })
        ->run;
    is $res->{result}, 3;
    is @stdout, 6;
    is @stderr, 0;
};

subtest array => sub {
    my ($stdout, $stderr) = ("", "");
    my  $res = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; exit 3'])
        ->stdout(sub { $stdout .= $_[0] })
        ->stderr(sub { $stderr .= $_[0] })
        ->run;
    is $res->{result} >> 8, 3;
    is $stdout, "2";
    is $stderr, "1";
};

subtest array_redirect => sub {
    my ($stdout, $stderr) = ("", "");
    my  $res = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; exit 3'])
        ->redirect(1)
        ->stdout(sub { $stdout .= $_[0] })
        ->stderr(sub { $stderr .= $_[0] })
        ->run;
    is $res->{result} >> 8, 3;
    is $stdout, "12";
    is $stderr, "";
};

subtest string => sub {
    my ($stdout, $stderr) = ("", "");
    my $res = Command::Runner->new
        ->commandf("%q -e %q", $^X, "warn 1; print 2; exit 3")
        ->stdout(sub { $stdout .= $_[0] })
        ->stderr(sub { $stderr .= $_[0] })
        ->run;
    is $res->{result} >> 8, 3;
    is $stdout, "2";
    is $stderr, "1 at -e line 1.";
};

subtest string_redirect => sub {
    my ($stdout, $stderr) = ("", "");
    my $res = Command::Runner->new
        ->commandf("%q -e %q", $^X, "warn 1; print 2; exit 3")
        ->redirect(1)
        ->stdout(sub { $stdout .= $_[0] })
        ->run;
    is $res->{result} >> 8, 3;
    is $stdout, "1 at -e line 1.2";
    is $stderr, "";
};

subtest timeout => sub {
    my $res = Command::Runner->new
        ->command([$^X, "-e", '$|++; warn "1\n"; print "2\n"; sleep 1'])
        ->timeout(0.5)
        ->run;
    ok $res->{timeout};
    is $res->{stdout}, "2\n";
    if ($windows) {
        # windows has garbage: Terminating on signal SIGBREAK(21)
    } else {
        is $res->{stderr}, "1\n";
    }
};

done_testing;
