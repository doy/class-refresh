package Foo;
use Moose;

has bar => (is => 'ro');

sub meth { $error }

no Moose;

1;
