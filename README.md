[![Build Status](https://travis-ci.org/skaji/Command-Runner.svg?branch=master)](https://travis-ci.org/skaji/Command-Runner)
[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/skaji/Command-Runner?branch=master&svg=true)](https://ci.appveyor.com/project/skaji/Command-Runner)

# NAME

Command::Runner - run external/Perl programs

# SYNOPSIS

    use Command::Runner;

    my $status = Command::Runner->new
      ->command(['ls', '-al'])
      ->timeout(10)
      ->on(stdout => sub { warn "out: $_[0]" })
      ->on(stderr => sub { warn "err: $_[0]" })
      ->on(timeout => sub { warn "timeout occurred" })
      ->run;

    my $ret = Command::Runner->new
      ->command(sub { warn 1; print 2 })
      ->redirect(1)
      ->on(stdout => sub { warn "merged: $_[0]" })
      ->run;

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
