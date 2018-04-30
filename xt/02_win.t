use strict;
use warnings;
use Test::More;
use File::Which 'which';
use Command::Runner;

for my $exe (qw(gzip tar git)) {
    my $cmd = which $exe;
    my $res = Command::Runner->new(redirect => 1, command => [$cmd, "--version"])->run;
    is $res->{result}, 0;
    my $out = $res->{stdout};
    chomp $out;
    note "";
    note "$cmd --version";
    note "out: $_" for split /\n/, $out;
}

done_testing;
