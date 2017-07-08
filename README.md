[![Build Status](https://travis-ci.org/skaji/Command-Runner.svg?branch=master)](https://travis-ci.org/skaji/Command-Runner)

# NAME

Command::Runner - run external/Perl programs

# SYNOPSIS

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

# DESCRIPTION

Command::Runner runs external/Perl programs.

# MOTIVATION

TBD

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
