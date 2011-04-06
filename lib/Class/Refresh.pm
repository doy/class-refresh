package Class::Refresh;
use strict;
use warnings;

use Class::Unload;
use Class::Load;

our %CACHE;

sub refresh {
    my $class = shift;

    $class->refresh_module($_) for $class->modified_modules;
}

sub modified_modules {
    my $class = shift;

    my @ret;
    for my $file (keys %INC) {
        if (exists $CACHE{$file}) {
            push @ret, $class->_file_to_mod($file)
                if $class->_mtime($file) ne $CACHE{$file};
        }
        else {
            $class->_update_cache_for($file);
        }
    }

    return @ret;
}

sub refresh_module {
    my $class = shift;
    my ($mod) = @_;
    $mod = $class->_file_to_mod($mod);

    my @to_refresh = $class->_dependent_modules($mod);

    $class->unload_module($_) for @to_refresh;
    $class->load_module($_) for @to_refresh;
}

sub unload_module {
    my $class = shift;
    my ($mod) = @_;
    $mod = $class->_file_to_mod($mod);

    Class::Unload->unload($mod);

    if (Class::Load::is_class_loaded('Class::MOP')) {
        Class::MOP::remove_metaclass_by_name($mod);
    }

    $class->_clear_cache_for($mod);
}

sub load_module {
    my $class = shift;
    my ($mod) = @_;
    $mod = $class->_file_to_mod($mod);

    Class::Load::load_class($mod);

    $class->_update_cache_for($mod);
}

sub _dependent_modules {
    my $class = shift;
    my ($mod) = @_;
    $mod = $class->_file_to_mod($mod);

    return ($mod) unless Class::Load::is_class_loaded('Class::MOP');

    my $meta = Class::MOP::class_of($mod);

    return ($mod) unless $meta;

    if ($meta->isa('Class::MOP::Class')) {
        # attribute cloning (has '+foo') means that we can't skip refreshing
        # mutable classes
        return (
            # NOTE: this order is important!
            $mod,
            map { $class->_dependent_modules($_) }
                ($meta->subclasses,
                 # XXX: metacircularity? what if $class is Class::MOP::Class?
                 ($mod->isa('Class::MOP::Class')
                     ? (map { $_->name }
                            grep { $_->isa($class) }
                                 Class::MOP::get_all_metaclass_instances())
                     : ())),
        );
    }
    elsif ($meta->isa('Moose::Meta::Role')) {
        return (
            $mod,
            map { $class->_dependent_modules($_) } $meta->consumers,
        );
    }
    else {
        die "Unknown metaclass: $meta";
    }
}

sub _update_cache_for {
    my $class = shift;
    my ($file) = @_;
    $file = $class->_mod_to_file($file);

    $CACHE{$file} = $class->_mtime($file);
}

sub _clear_cache_for {
    my $class = shift;
    my ($file) = @_;
    $file = $class->_mod_to_file($file);

    delete $CACHE{$file};
}

sub _mtime {
    my $class = shift;
    my ($file) = @_;
    $file = $class->_mod_to_file($file);

    return join ' ', (stat($INC{$file}))[1, 7, 9];
}

sub _file_to_mod {
    my $class = shift;
    my ($file) = @_;

    return $file unless $file =~ /\.pm$/;

    my $mod = $file;
    $mod =~ s{\.pm$}{};
    $mod =~ s{/}{::}g;

    return $mod;
}

sub _mod_to_file {
    my $class = shift;
    my ($mod) = @_;

    return $mod if $mod =~ /\.p[lm]$/;

    my $file = $mod;
    $file =~ s{::}{/}g;
    $file .= '.pm';

    return $file;
}

1;
