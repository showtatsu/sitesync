#!/bin/env perl
use strict;
use warnings;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), '../modules');

use RsyncConfig;

my $c = RsyncConfig->new;
my ($src, $dst);
foreach my $cmdarg (@ARGV) {
	if ($cmdarg =~ /^-/ ) {
		$c->set_from_cmdopt($cmdarg) or die "ERR:$?";
	} else {
		if (not defined $src) {
			$c->{source} = ($src = $cmdarg);
		} elsif (not defined $dst) {
			$c->{destination} = ($dst = $cmdarg);
		} else {
			die "ERR:-1";
		}
	}
}
print $c->to_json;

