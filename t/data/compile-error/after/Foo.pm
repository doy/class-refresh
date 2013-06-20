package Foo;
use Moose;

has bar => (is => 'ro');

sub meth { my $error; }

no Moose;

1;
