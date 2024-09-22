# -*- mode: Perl; buffer-read-only: t -*-
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!
# This file is built by regen/feature.pl.
# Any changes made here will be lost!

package feature;
our $VERSION = '1.82';

our %feature = (
    fc                      => 'feature_fc',
    isa                     => 'feature_isa',
    say                     => 'feature_say',
    try                     => 'feature_try',
    class                   => 'feature_class',
    defer                   => 'feature_defer',
    state                   => 'feature_state',
    switch                  => 'feature_switch',
    bitwise                 => 'feature_bitwise',
    indirect                => 'feature_indirect',
    evalbytes               => 'feature_evalbytes',
    signatures              => 'feature_signatures',
    current_sub             => 'feature___SUB__',
    module_true             => 'feature_module_true',
    refaliasing             => 'feature_refaliasing',
    postderef_qq            => 'feature_postderef_qq',
    unicode_eval            => 'feature_unieval',
    declared_refs           => 'feature_myref',
    unicode_strings         => 'feature_unicode',
    multidimensional        => 'feature_multidimensional',
    bareword_filehandles    => 'feature_bareword_filehandles',
    extra_paired_delimiters => 'feature_more_delims',
);

our %feature_bundle = (
    "5.10"    => [qw(bareword_filehandles indirect multidimensional say state switch)],
    "5.11"    => [qw(bareword_filehandles indirect multidimensional say state switch unicode_strings)],
    "5.15"    => [qw(bareword_filehandles current_sub evalbytes fc indirect multidimensional say state switch unicode_eval unicode_strings)],
    "5.23"    => [qw(bareword_filehandles current_sub evalbytes fc indirect multidimensional postderef_qq say state switch unicode_eval unicode_strings)],
    "5.27"    => [qw(bareword_filehandles bitwise current_sub evalbytes fc indirect multidimensional postderef_qq say state switch unicode_eval unicode_strings)],
    "5.35"    => [qw(bareword_filehandles bitwise current_sub evalbytes fc isa postderef_qq say signatures state unicode_eval unicode_strings)],
    "5.37"    => [qw(bitwise current_sub evalbytes fc isa module_true postderef_qq say signatures state unicode_eval unicode_strings)],
    "all"     => [qw(bareword_filehandles bitwise class current_sub declared_refs defer evalbytes extra_paired_delimiters fc indirect isa module_true multidimensional postderef_qq refaliasing say signatures state switch try unicode_eval unicode_strings)],
    "default" => [qw(bareword_filehandles indirect multidimensional)],
);

$feature_bundle{"5.12"} = $feature_bundle{"5.11"};
$feature_bundle{"5.13"} = $feature_bundle{"5.11"};
$feature_bundle{"5.14"} = $feature_bundle{"5.11"};
$feature_bundle{"5.16"} = $feature_bundle{"5.15"};
$feature_bundle{"5.17"} = $feature_bundle{"5.15"};
$feature_bundle{"5.18"} = $feature_bundle{"5.15"};
$feature_bundle{"5.19"} = $feature_bundle{"5.15"};
$feature_bundle{"5.20"} = $feature_bundle{"5.15"};
$feature_bundle{"5.21"} = $feature_bundle{"5.15"};
$feature_bundle{"5.22"} = $feature_bundle{"5.15"};
$feature_bundle{"5.24"} = $feature_bundle{"5.23"};
$feature_bundle{"5.25"} = $feature_bundle{"5.23"};
$feature_bundle{"5.26"} = $feature_bundle{"5.23"};
$feature_bundle{"5.28"} = $feature_bundle{"5.27"};
$feature_bundle{"5.29"} = $feature_bundle{"5.27"};
$feature_bundle{"5.30"} = $feature_bundle{"5.27"};
$feature_bundle{"5.31"} = $feature_bundle{"5.27"};
$feature_bundle{"5.32"} = $feature_bundle{"5.27"};
$feature_bundle{"5.33"} = $feature_bundle{"5.27"};
$feature_bundle{"5.34"} = $feature_bundle{"5.27"};
$feature_bundle{"5.36"} = $feature_bundle{"5.35"};
$feature_bundle{"5.38"} = $feature_bundle{"5.37"};
$feature_bundle{"5.9.5"} = $feature_bundle{"5.10"};
my %noops = (
    postderef => 1,
    lexical_subs => 1,
);
my %removed = (
    array_base => 1,
);

our $hint_shift   = 26;
our $hint_mask    = 0x3c000000;
our @hint_bundles = qw( default 5.10 5.11 5.15 5.23 5.27 5.35 5.37 );

# This gets set (for now) in $^H as well as in %^H,
# for runtime speed of the uc/lc/ucfirst/lcfirst functions.
# See HINT_UNI_8_BIT in perl.h.
our $hint_uni8bit = 0x00000800;

# TODO:
# - think about versioned features (use feature switch => 2)

sub import {
    shift;

    if (!@_) {
        croak("No features specified");
    }

    __common(1, @_);
}

sub unimport {
    shift;

    # A bare C<no feature> should reset to the default bundle
    if (!@_) {
	$^H &= ~($hint_uni8bit|$hint_mask);
	return;
    }

    __common(0, @_);
}

sub __common {
    my $import = shift;
    my $bundle_number = $^H & $hint_mask;
    my $features = $bundle_number != $hint_mask
      && $feature_bundle{$hint_bundles[$bundle_number >> $hint_shift]};
    if ($features) {
	# Features are enabled implicitly via bundle hints.
	# Delete any keys that may be left over from last time.
	delete @^H{ values(%feature) };
	$^H |= $hint_mask;
	for (@$features) {
	    $^H{$feature{$_}} = 1;
	    $^H |= $hint_uni8bit if $_ eq 'unicode_strings';
	}
    }
    while (@_) {
        my $name = shift;
        if (substr($name, 0, 1) eq ":") {
            my $v = substr($name, 1);
            if (!exists $feature_bundle{$v}) {
                $v =~ s/^([0-9]+)\.([0-9]+).[0-9]+$/$1.$2/;
                if (!exists $feature_bundle{$v}) {
                    unknown_feature_bundle(substr($name, 1));
                }
            }
            unshift @_, @{$feature_bundle{$v}};
            next;
        }
        if (!exists $feature{$name}) {
            if (exists $noops{$name}) {
                next;
            }
            if (!$import && exists $removed{$name}) {
                next;
            }
            unknown_feature($name);
        }
	if ($import) {
	    $^H{$feature{$name}} = 1;
	    $^H |= $hint_uni8bit if $name eq 'unicode_strings';
	} else {
            delete $^H{$feature{$name}};
            $^H &= ~ $hint_uni8bit if $name eq 'unicode_strings';
        }
    }
}

sub unknown_feature {
    my $feature = shift;
    croak(sprintf('Feature "%s" is not supported by Perl %vd',
            $feature, $^V));
}

sub unknown_feature_bundle {
    my $feature = shift;
    croak(sprintf('Feature bundle "%s" is not supported by Perl %vd',
            $feature, $^V));
}

sub croak {
    require Carp;
    Carp::croak(@_);
}

sub features_enabled {
    my ($depth) = @_;

    $depth //= 1;
    my @frame = caller($depth+1)
      or return;
    my ($hints, $hinthash) = @frame[8, 10];

    my $bundle_number = $hints & $hint_mask;
    if ($bundle_number != $hint_mask) {
        return $feature_bundle{$hint_bundles[$bundle_number >> $hint_shift]}->@*;
    }
    else {
        my @features;
        for my $feature (sort keys %feature) {
            if ($hinthash->{$feature{$feature}}) {
                push @features, $feature;
            }
        }
        return @features;
    }
}

sub feature_enabled {
    my ($feature, $depth) = @_;

    $depth //= 1;
    my @frame = caller($depth+1)
      or return;
    my ($hints, $hinthash) = @frame[8, 10];

    my $hint_feature = $feature{$feature}
      or croak "Unknown feature $feature";
    my $bundle_number = $hints & $hint_mask;
    if ($bundle_number != $hint_mask) {
        my $bundle = $hint_bundles[$bundle_number >> $hint_shift];
        for my $bundle_feature ($feature_bundle{$bundle}->@*) {
            return 1 if $bundle_feature eq $feature;
        }
        return 0;
    }
    else {
        return $hinthash->{$hint_feature} // 0;
    }
}

sub feature_bundle {
    my $depth = shift;

    $depth //= 1;
    my @frame = caller($depth+1)
      or return;
    my $bundle_number = $frame[8] & $hint_mask;
    if ($bundle_number != $hint_mask) {
        return $hint_bundles[$bundle_number >> $hint_shift];
    }
    else {
        return undef;
    }
}

1;

# ex: set ro ft=perl: