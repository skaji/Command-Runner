[![Actions Status](https://github.com/skaji/Command-Runner/actions/workflows/test.yml/badge.svg)](https://github.com/skaji/Command-Runner/actions)

# NAME

Command::Runner - run external commands and Perl code refs

# SYNOPSIS

    use Command::Runner;

    my $cmd = Command::Runner->new(
      command => ['ls', '-al'],
      timeout => 10,
      stdout  => sub { warn "out: $_[0]\n" },
      stderr  => sub { warn "err: $_[0]\n" },
    );
    my $res = $cmd->run;

# DESCRIPTION

Command::Runner runs external commands and Perl code refs

# METHODS

## new

A constructor, which takes:

- command

    an array of external commands, a string of external programs, or a Perl code ref.
    If an array of external commands is specified, it is automatically quoted on Windows.

- timeout

    timeout second. You can set float second.

- redirect

    if this is true, stderr redirects to stdout

- keep

    by default, even if stdout/stderr is consumed, it is preserved for return value.
    You can disable this behavior by setting keep option false.

- stdout / stderr

    a code ref that will be called whenever stdout/stderr is available

- env

    set environment variables.

        Command::Runner->new(..., env => \%env)->run

    is roughly equivalent to

        {
          local %ENV = %env;
          Command::Runner->new(...)->run;
        }

- cwd

    set the current directory.

        Command::Runner->new(..., cwd => $dir)->run

    is roughly equivalent to

        {
          require File::pushd;
          my $guard = File::pushd::pushd($dir);
          Command::Runner->new(...)->run;
        }

## run

Run command. It returns a hash reference, which contains:

- result
- timeout
- stdout
- stderr
- pid

# MOTIVATION

I develop a CPAN client [App::cpm](https://metacpan.org/pod/App%3A%3Acpm), where I need to execute external commands and Perl code refs with:

- timeout
- quoting
- flexible logging

While [App::cpanminus](https://metacpan.org/pod/App%3A%3Acpanminus) has excellent APIs for such use, I still needed to tweak them in [App::cpm](https://metacpan.org/pod/App%3A%3Acpm).

So I ended up creating a seperate module, Command::Runner.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
