use strict;
use warnings;

use Test::More;

use Command::Runner;
use Cwd qw(getcwd abs_path);
use File::Basename 'dirname';
use File::Temp 'tempdir';

subtest external => sub {
    my $tempdir = tempdir CLEANUP => 1;
    $tempdir = abs_path $tempdir;
    chdir $tempdir or die;
    my $dir = dirname $tempdir;
    if ($tempdir eq $dir) {
        die;
    }

    my ($command_dir, $stdout_cb_dir);
    my $cmd = Command::Runner->new(
        command => [ $^X, "-MCwd=getcwd,abs_path", "-le", 'sleep 1; print abs_path getcwd;' ],
        cwd => $dir,
        stdout => sub {
            my $line = shift;
            chomp $line;
            $command_dir = $line;
            $stdout_cb_dir = abs_path getcwd;
        },
        keep => 1,
    );
    my $res = $cmd->run;
    is abs_path(getcwd()), $tempdir;
    is $dir, $command_dir;
    is $tempdir, $stdout_cb_dir;
    chdir "/";
};

subtest code => sub {
    my $tempdir = tempdir CLEANUP => 1;
    $tempdir = abs_path $tempdir;
    chdir $tempdir or die;
    my $dir = dirname $tempdir;
    if ($tempdir eq $dir) {
        die;
    }

    my ($command_dir, $stdout_cb_dir);
    my $cmd = Command::Runner->new(
        command => sub {
            print abs_path(getcwd), "\n";
        },
        cwd => $dir,
        stdout => sub {
            my $line = shift;
            chomp $line;
            $command_dir = $line;
            $stdout_cb_dir = abs_path getcwd;
        },
        keep => 1,
    );
    my $res = $cmd->run;
    is abs_path(getcwd()), $tempdir;
    is $dir, $command_dir;
    is $tempdir, $stdout_cb_dir;
    chdir "/";
};

subtest external_with_env => sub {
    my $tempdir = tempdir CLEANUP => 1;
    $tempdir = abs_path $tempdir;
    chdir $tempdir or die;
    my $dir = dirname $tempdir;
    if ($tempdir eq $dir) {
        die;
    }

    delete $ENV{FOO};
    my ($command_dir, $stdout_cb_dir, $command_env, $stdout_cb_env);
    my $cmd = Command::Runner->new(
        command => [ $^X, "-MCwd=getcwd,abs_path", "-le", 'sleep 1; print abs_path getcwd; print $ENV{FOO};' ],
        cwd => $dir,
        env => { %ENV, FOO => 'BAR' },
        stdout => sub {
            my $line = shift;
            chomp $line;
            if ($command_dir) {
                $command_env = $line;
            } else {
                $command_dir = $line;
            }
            $stdout_cb_dir = abs_path getcwd;
            $stdout_cb_env = $ENV{FOO};
        },
        keep => 1,
    );
    my $res = $cmd->run;
    is abs_path(getcwd()), $tempdir;
    is $command_dir, $dir;
    is $stdout_cb_dir, $tempdir;
    is $command_env, 'BAR';
    is $stdout_cb_env, undef;
    chdir "/";
};

subtest code_with_env => sub {
    my $tempdir = tempdir CLEANUP => 1;
    $tempdir = abs_path $tempdir;
    chdir $tempdir or die;
    my $dir = dirname $tempdir;
    if ($tempdir eq $dir) {
        die;
    }

    delete $ENV{FOO};
    my ($command_dir, $stdout_cb_dir, $command_env, $stdout_cb_env);
    my $cmd = Command::Runner->new(
        command => sub {
            print abs_path(getcwd), "\n";
            print $ENV{FOO}, "\n";
        },
        cwd => $dir,
        env => { %ENV, FOO => 'BAR' },
        stdout => sub {
            my $line = shift;
            chomp $line;
            if ($command_dir) {
                $command_env = $line;
            } else {
                $command_dir = $line;
            }
            $stdout_cb_dir = abs_path getcwd;
            $stdout_cb_env = $ENV{FOO};
        },
        keep => 1,
    );
    my $res = $cmd->run;
    is abs_path(getcwd()), $tempdir;
    is $command_dir, $dir;
    is $stdout_cb_dir, $tempdir;
    is $command_env, 'BAR';
    is $stdout_cb_env, undef;
    chdir "/";
};

done_testing;
