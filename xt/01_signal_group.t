use strict;
use warnings;
use Test::More;
use Command::Runner;
use File::Temp ();

plan skip_all => 'disable on windows' if $^O eq 'MSWin32';

my $code = <<'___';
use strict;
use warnings;

my $filename = shift @ARGV;

my $pid = fork;
die unless defined $pid;

if ($pid == 0) {
    my $TERM; $SIG{TERM} = sub { $TERM++ };
    while (!$TERM) {
        sleep 1;
    }
    if ($TERM) {
        open my $fh, ">>", $filename or die;
        print {$fh} "GOT SIGTERM\n";
    }
    exit 0;
}

wait;
exit;
___

my (undef, $filename) = File::Temp::tempfile UNLINK => 0, EXLOCK => 0, OPEN => 0;

my ($ret, $is_timeout) = Command::Runner->new
    ->command([$^X, "-e", $code, $filename])
    ->timeout(0.5)
    ->run;
is $ret, 15; # SIGTERM
ok $is_timeout;
open my $fh, "<", $filename or die "$filename: $!";
my $line = <$fh>;
is $line, "GOT SIGTERM\n";
unlink $filename;

done_testing;
