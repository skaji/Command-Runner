[![Build Status](https://travis-ci.org/skaji/Command-Runner.svg?branch=master)](https://travis-ci.org/skaji/Command-Runner)
[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/skaji/Command-Runner?branch=master&svg=true)](https://ci.appveyor.com/project/skaji/Command-Runner)

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

    my $untar = Command::Runner->new;
    $untar->commandf(
      '%q -dc %q | %q tf -',
      'C:\\Program Files (x86)\\GnuWin32\\bin\\gzip.EXE',
      'File-ShareDir-Install-0.13.tar.gz'
      'C:\\Program Files (x86)\\GnuWin32\\bin\\tar.EXE',
    );
    my $capture = $untar->run->{stdout};

# DESCRIPTION

Command::Runner runs external commands and Perl code refs

# METHODS

## new

A constructor, which takes:

- command

    an array of external commands, a string of external programs, or a Perl code ref.
    If an array of external commands is specified, it is automatically quoted on Windows.

- commandf

    a command string by `sprintf`-like syntax.
    You can use positional formatting with conversions `%q` (with quoting) and `%s` (as it is).

    Here is an example:

        my $cmd = Command::Runner->new(
          commandf => [ '%q %q >> %q', '/path/to/cat', 'foo bar.txt', 'out.txt' ],
        );

        # or, you can set it separately
        my $cmd = Command::Runner->new;
        $cmd->commandf('%q %q >> %q', '/path/to/cat', 'foo bar.txt', 'out.txt');

    See [String::Formatter](https://metacpan.org/pod/String::Formatter) for details.

- timeout

    timeout second. You can set float second.

- redirect

    if this is true, stderr redirects to stdout

- keep

    by default, even if stdout/stderr is consumed, it is preserved for return value.
    You can disable this behavior by setting keep option false.

- stdout / stderr

    a code ref that will be called whenever stdout/stderr is available

## run

Run command. It returns a hash reference, which contains:

- result
- timeout
- stdout
- stderr
- pid

# MOTIVATION

I develop a CPAN client [App::cpm](https://metacpan.org/pod/App::cpm), where I need to execute external commands and Perl code refs with:

- timeout
- quoting
- flexible logging

While [App::cpanminus](https://metacpan.org/pod/App::cpanminus) has excellent APIs for such use, I still needed to tweak them in [App::cpm](https://metacpan.org/pod/App::cpm).

So I ended up creating a seperate module, Command::Runner.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
