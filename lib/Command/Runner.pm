package Command::Runner;
use strict;
use warnings;

use Capture::Tiny ();
use Command::Runner::LineBuffer;
use Config ();
use IO::Select;
use POSIX ();
use Time::HiRes ();

use constant WIN32 => $^O eq 'MSWin32';

our $VERSION = '0.001';
our $TICK = 0.05;

sub new {
    my ($class, %option) = @_;
    bless {
        %option,
        buffer   => {},
        on       => {},
    }, $class;
}

for my $attr (qw(command redirect timeout)) {
    no strict 'refs';
    *$attr = sub {
        my $self = shift;
        @_ > 0 ? $self->{$attr} = $_[0] : $self->{$attr};
    };
}

sub on {
    my ($self, $type, $sub) = @_;
    my %valid = map { $_ => 1 } qw(stdout stderr timeout);
    if (!$valid{$type}) {
        die "unknown type '$type' passes to on() method";
    }
    $self->{on}{$type} = $sub;
    $self;
}

sub run {
    my $self = shift;
    my $command = $self->{command};
    if (WIN32) {
        $self->_run($command);
    } else {
        my $ref = ref $command;
        if (!$ref || $ref eq 'ARRAY') {
            $self->_exec($command);
        } else {
            $self->_run($command);
        }
    }
}

sub _run {
    my ($self, $command) = @_;
    my $sub;
    my $ref = ref $command;
    if ($ref eq 'CODE') {
        $sub = $command;
    } elsif (!$ref) {
        $sub = sub { system $command };
    } else {
        $sub = sub { system { $command->[0] } @$command };
    }

    my ($stdout, $stderr, $ret);
    if ($self->{redirect}) {
        ($stdout, $ret) = &Capture::Tiny::capture_merged($sub);
    } else {
        ($stdout, $stderr, $ret) = &Capture::Tiny::capture($sub);
    }

    if (my $sub = $self->{on}{stdout}) {
        while ($stdout =~ s/\A(.*?\n)//sm) {
            $sub->($1);
        }
        $sub->($stdout) if length $stdout;
    }
    if (!$self->{redirect} and my $sub = $self->{on}{stderr}) {
        while ($stderr =~ s/\A(.*?\n)//sm) {
            $sub->($1);
        }
        $sub->($stderr) if length $stderr;
    }

    return $ret;
}

sub _exec {
    my ($self, $command) = @_;
    pipe my $stdout_read, my $stdout_write;
    my ($stderr_read, $stderr_write);
    pipe $stderr_read, $stderr_write unless $self->{redirect};
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $_ for grep $_, $stdout_read, $stderr_read;
        open STDOUT, ">&", $stdout_write;
        if ($self->{redirect}) {
            open STDERR, ">&", \*STDOUT;
        } else {
            open STDERR, ">&", $stderr_write;
        }
        if ($Config::Config{d_setpgrp}) {
            POSIX::setpgid(0, 0) or die "setpgid: $!";
        }

        if (ref $command) {
            exec { $command->[0] } @$command;
        } else {
            exec $command;
        }
        exit 127;
    }
    close $_ for grep $_, $stdout_write, $stderr_write;

    my $INT; local $SIG{INT} = sub { $INT++ };
    my $is_timeout;
    my $timeout_at = $self->{timeout} ? Time::HiRes::time() + $self->{timeout} : undef;
    my $select = IO::Select->new(grep $_, $stdout_read, $stderr_read);
    while (1) {
        last if $INT;
        last if $select->count == 0;
        for my $ready ($select->can_read($TICK)) {
            my $type = $ready == $stdout_read ? "stdout" : "stderr";
            my $len = sysread $ready, my $buf, 64*1024;
            if (!defined $len) {
                warn "sysread pipe failed: $!";
                last;
            } elsif ($len == 0) {
                $select->remove($ready);
                close $ready;
            } else {
                my $buffer = $self->{buffer}{$type} ||= Command::Runner::LineBuffer->new;
                $buffer->append($buf);
                my @line = $buffer->get;
                next unless @line;
                next unless my $sub = $self->{on}{$type};
                $sub->($_) for @line;
            }
        }
        if ($timeout_at) {
            my $now = Time::HiRes::time();
            if ($now > $timeout_at) {
                $is_timeout++;
                last;
            }
        }
    }
    for my $type (qw(stdout stderr)) {
        my $buffer = $self->{buffer}{$type} or next;
        my @line = $buffer->get(1) or next;
        next unless my $sub = $self->{on}{$type};
        $sub->($_) for @line;
    }
    close $_ for $select->handles;
    if ($INT && kill 0 => $pid) {
        my $target = $Config::Config{d_setpgrp} ? -$pid : $pid;
        kill INT => $target;
    }
    if ($is_timeout && kill 0 => $pid) {
        if (my $on_timeout = $self->{on}{timeout}) {
            $on_timeout->($pid);
        }
        my $target = $Config::Config{d_setpgrp} ? -$pid : $pid;
        kill TERM => $target;
    }
    waitpid $pid, 0;
    return $?;
}

1;
__END__

=encoding utf-8

=head1 NAME

Command::Runner - run external/Perl programs

=head1 SYNOPSIS

  use Command::Runner;

  my $runner = Command::Runner->new(command => ['ls', '-al']);
  $runner->timeout(10);
  $runner->on(stdout => sub { warn "out: $_[0]" });
  $runner->on(stderr => sub { warn "err: $_[0]" });
  $runner->on(timeout => sub { warn "timeout occurred." });
  my $status = $runner->run;

  $runner = Command::Runner->new(command => sub { warn 1; print 2 });
  $runner->redirect(1);
  $runner->on(stdout => sub { warn "merged: $_[0]" });
  my $ret = $runner->run;

=head1 DESCRIPTION

Command::Runner runs external/Perl programs.

=head1 MOTIVATION

TBD

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
