[![Build Status](https://travis-ci.org/skaji/Command-Runner.svg?branch=master)](https://travis-ci.org/skaji/Command-Runner)
[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/skaji/Command-Runner?branch=master&svg=true)](https://ci.appveyor.com/project/skaji/Command-Runner)

# NAME

Command::Runner - run external commands and Perl code refs

# SYNOPSIS

    use Command::Runner;

    my $cmd = Command::Runner->new(
      command => ['ls', '-al'],
      timeout => 10,
      on => {
        stdout => sub { warn "out: $_[0]\n" },
        stderr => sub { warn "err: $_[0]\n" },
      },
    );
    my $res = $cmd->run;

    # you can also use method chains
    my $res = Command::Runner->new
      ->command(sub { warn 1; print 2 })
      ->redirect(1)
      ->on(stdout => sub { warn "merged: $_[0]" })
      ->run;

# DESCRIPTION

Command::Runner runs external commands and Perl code refs

# METHODS

## new

A constructor, which takes:

- command

    arrays of external commands, strings of external programs, or Perl code refs

    **CAUTION!** Currently this module does NOTHING for quoting.
    YOU are responsible to quote argument lists. See [Win32::ShellQuote](https://metacpan.org/pod/Win32::ShellQuote) and [String::ShellQuote](https://metacpan.org/pod/String::ShellQuote).

- timeout

    timeout second. You can set float second.

- redirect

    if this is true, stderr redirects to stdout

- keep

    by default, if stdout/stderr is consumed, it will disappear. Disable this by setting keep option true

- on.stdout, on.stderr

    code refs that will be called whenever stdout/stderr is available

## run

Run command. It returns a hash reference, which contains:

- result
- timeout
- stdout
- stderr

# MOTIVATION

I develop a CPAN client [App::cpm](https://metacpan.org/pod/App::cpm), where I need to execute external commands and Perl code refs with:

- timeout
- flexible logging
- high portability

While [App::cpanminus](https://metacpan.org/pod/App::cpanminus) has excellent APIs for such use, I still needed to tweak them in [App::cpm](https://metacpan.org/pod/App::cpm).

So I ended up creating a seperate module, Command::Runner.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
