package Command::Runner::LineBuffer;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless { buffer => "" }, $class;
}

sub append {
    my ($self, $buffer) = @_;
    $self->{buffer} .= $buffer;
    $self;
}

sub get {
    my ($self, $drain) = @_;
    if ($drain) {
        if (length $self->{buffer}) {
            my @line = $self->get;
            if (length $self->{buffer}) {
                push @line, $self->{buffer};
                $self->{buffer} = "";
            }
            return @line;
        } else {
            return;
        }
    }
    my @line;
    while ($self->{buffer} =~ s/\A(.*?\n)//sm) {
        push @line, $1;
    }
    return @line;
}

1;
