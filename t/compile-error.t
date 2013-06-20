#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Requires 'Moose';
use lib 't/lib';
use Test::Class::Refresh;
use Try::Tiny;

use Class::Refresh;

my $dir = prepare_temp_dir_for('compile-error');
push @INC, $dir->dirname;

require Foo;

Class::Refresh->refresh;

my $foo = Foo->new;
lives_ok { $foo->meth } '$foo->meth works';


sleep 2;
update_temp_dir_for('compile-error', $dir, 'middle');

try {
Class::Refresh->refresh;
};

dies_ok { $foo->meth } '$foo->meth doesnt work now';

sleep 2;
update_temp_dir_for('compile-error', $dir, 'after');

try {
Class::Refresh->refresh;
};

lives_ok { $foo->meth } '$foo->meth works again';


done_testing;
