#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh;

my $dir = prepare_temp_dir_for('basic');
push @INC, $dir->dirname;

require Foo;

Class::Refresh->refresh;

can_ok('Foo', 'meth');
ok(!Foo->can('other_meth'), "!Foo->can('other_meth')");


sleep 2;
update_temp_dir_for('basic', $dir);

Class::Refresh->refresh;

can_ok('Foo', 'other_meth');
ok(!Foo->can('meth'), "!Foo->can('meth')");

done_testing;
