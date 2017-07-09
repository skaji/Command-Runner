requires 'perl', '5.008001';

requires 'Capture::Tiny';
requires 'Win32::ShellQuote';

on develop => sub {
    requires 'Test2::Harness';
};
