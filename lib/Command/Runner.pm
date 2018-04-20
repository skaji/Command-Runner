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
        _buffer => {},
        on => {},
        %option,
    }, $class;
}

for my $attr (qw(command redirect timeout)) {
    no strict 'refs';
    *$attr = sub {
        my $self = shift;
        if (@_) {
            $self->{$attr} = $_[0];
            $self;
        } else {
            $self->{$attr};
        }
    };
}

sub on {
    my ($self, $type, $sub) = @_;
    if ($sub) {
        $self->{on}{$type} = $sub;
        $self;
    } else {
        $self->{on}{$type};
    }
}

sub run {
    my $self = shift;
    my $command = $self->{command};
    my ($exit, $is_timeout);
    if (ref $command eq 'CODE') {
        ($exit, $is_timeout) = $self->_wrap(sub { $self->_run_code($command) });
    } elsif (WIN32) {
        ($exit, $is_timeout) = $self->_wrap(sub { $self->_system_win32($command) });
    } else {
        ($exit, $is_timeout) = $self->_exec($command);
    }
    wantarray ? ($exit, $is_timeout) : $exit;
}

sub _wrap {
    my ($self, $code) = @_;

    my ($stdout, $stderr, $ret, $is_timeout);
    if ($self->{redirect}) {
        ($stdout, $ret, $is_timeout) = &Capture::Tiny::capture_merged($code);
    } else {
        ($stdout, $stderr, $ret, $is_timeout) = &Capture::Tiny::capture($code);
    }

    if (length $stdout and my $sub = $self->{on}{stdout}) {
        my $buffer = Command::Runner::LineBuffer->new($stdout);
        my @line = $buffer->get(1);
        $sub->($_) for @line;
    }
    if (!$self->{redirect} and length $stderr and my $sub = $self->{on}{stderr}) {
        my $buffer = Command::Runner::LineBuffer->new($stderr);
        my @line = $buffer->get(1);
        $sub->($_) for @line;
    }

    return ($ret, $is_timeout);
}

sub _run_code {
    my ($self, $code) = @_;

    if (!$self->{timeout}) {
        my $ret = $code->();
        return ($ret, undef);
    }

    my ($ret, $err);
    {
        local $SIG{__DIE__} = 'DEFAULT';
        local $SIG{ALRM} = sub { die "__TIMEOUT__\n" };
        eval {
            alarm $self->{timeout};
            $ret = $code->();
        };
        $err = $@;
        alarm 0;
    }
    return ($ret, undef) unless $err;
    if ($err eq "__TIMEOUT__\n") {
        return ($ret, 1);
    } else {
        die $err;
    }
}

sub _system_win32 {
    my ($self, $command) = @_;
    my $pid = system 1, ref $command ? @$command : $command;

    my $timeout_at = $self->{timeout} ? Time::HiRes::time() + $self->{timeout} : undef;
    my $INT; local $SIG{INT} = sub { $INT++ };
    my ($exit, $is_timeout);
    while (1) {
        if ($INT) {
            kill INT => $pid;
            $INT = 0;
        }

        my $ret = waitpid $pid, POSIX::WNOHANG();
        if ($ret == -1) {
            warn "waitpid($pid, POSIX::WNOHANG()) returns unexpectedly -1";
            last;
        } elsif ($ret > 0) {
            $exit = $?;
            last;
        } else {
            if ($timeout_at) {
                my $now = Time::HiRes::time();
                if ($timeout_at <= $now) {
                    $is_timeout = 1;
                    kill TERM => $pid;
                }
            }
            Time::HiRes::sleep($TICK);
        }
    }
    return ($exit, $is_timeout);
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

    my $signal_pid = $Config::Config{d_setpgrp} ? -$pid : $pid;

    my $INT; local $SIG{INT} = sub { $INT++ };
    my $is_timeout;
    my $timeout_at = $self->{timeout} ? Time::HiRes::time() + $self->{timeout} : undef;
    my $select = IO::Select->new(grep $_, $stdout_read, $stderr_read);
    while (1) {
        if ($INT) {
            kill INT => $signal_pid;
            last;
        }

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
                next unless my $sub = $self->{on}{$type};
                my $buffer = $self->{_buffer}{$type} ||= Command::Runner::LineBuffer->new;
                $buffer->add($buf);
                next unless my @line = $buffer->get;
                $sub->($_) for @line;
            }
        }
        if ($timeout_at) {
            my $now = Time::HiRes::time();
            if ($now > $timeout_at) {
                $is_timeout++;
                kill TERM => $signal_pid;
                last;
            }
        }
    }
    for my $type (qw(stdout stderr)) {
        next unless my $sub = $self->{on}{$type};
        my $buffer = $self->{_buffer}{$type} or next;
        my @line = $buffer->get(1) or next;
        $sub->($_) for @line;
    }
    close $_ for $select->handles;
    waitpid $pid, 0;
    my $status = $?;
    $self->{_buffer} = +{}; # cleanup
    return ($status, $is_timeout);
}

1;
__END__

=encoding utf-8

=head1 NAME

Command::Runner - run external commands and Perl code refs

=head1 SYNOPSIS

  use Command::Runner;

  my $cmd = Command::Runner->new(
    command => ['ls', '-al'],
    timeout => 10,
    on => {
      stdout => sub { warn "out: $_[0]\n" },
      stderr => sub { warn "err: $_[0]\n" },
    },
  );
  my ($status, $is_timeout) = $cmd->run;

  # you can also use method chains
  my $ret = Command::Runner->new
    ->command(sub { warn 1; print 2 })
    ->redirect(1)
    ->on(stdout => sub { warn "merged: $_[0]" })
    ->run;

=head1 DESCRIPTION

Command::Runner runs external commands and Perl code refs

=head1 METHODS

=head2 new

A constructor, which takes:

=over 4

=item command

arrays of external commands, strings of external programs, or Perl code refs

B<CAUTION!> Currently this module does NOTHING for quoting.
YOU are responsible to quote argument lists. See L<Win32::ShellQuote> and L<String::ShellQuote>.

=item timeout

timeout second. You can set float second.

=item redirect

if this is true, stderr redirects to stdout

=item on.stdout, on.stderr

code refs that will be called whenever stdout/stderr is available

=back

=head2 run

Run command. It returns C<< ($status, $is_timeout) >> in list context, and C<< $status >> in scalar context.

=head1 MOTIVATION

I develop a CPAN client L<App::cpm>, where I need to execute external commands and Perl code refs with:

=over 4

=item timeout

=item flexible logging

=item high portability

=back

While L<App::cpanminus> has excellent APIs for such use, I still needed to tweak them in L<App::cpm>.

So I ended up creating a seperate module, Command::Runner.

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
