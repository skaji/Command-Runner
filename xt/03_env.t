use strict;
use warnings;
use Test::More;
use Command::Runner;

{
    my $res = Command::Runner->new(
        command => [$^X, '-e', 'print "$ENV{FOO} $ENV{PATH}"'],
        env => +{ %ENV, FOO => 1 },
        keep => 1,
    )->run;
    is $res->{stdout}, "1 $ENV{PATH}";
}
{
    my $res = Command::Runner->new(
        command => [$^X, '-e', 'print "$ENV{FOO} $ENV{PATH}"'],
        keep => 1,
    )->run;
    is $res->{stdout}, " $ENV{PATH}";
}

done_testing;
