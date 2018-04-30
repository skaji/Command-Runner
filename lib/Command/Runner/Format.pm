package Command::Runner::Format;
use strict;
use warnings;

use String::Formatter ();
use Command::Runner::Quote 'quote';

use Exporter 'import';
our @EXPORT_OK = qw(commandf);

my $formatter = String::Formatter->new({
    codes => {
        q => sub { quote $_ },
        s => sub { $_ },
        d => sub { 0+$_ },
    },
});

sub commandf {
    my ($format, @args) = @_;
    $formatter->format($format, @args);
}

1;
