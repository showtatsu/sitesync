package Restrict;
use strict;
use warnings;
use File::Spec;
use File::Basename;
use lib dirname(__FILE__);
use RsyncConfig;

sub new {
	my $class = shift;
	my $conf  = shift;
	my $self = bless +{
		config => $conf,
	}, $class;
	return $self;
}

sub check {
	my $self = shift;
	my $input = shift;
	my $rules = $self->{config};
	foreach my $rule (@$rules) {
		my $rx = qr/$rule->{pattern}/;
		my $result = ($input =~ $rx);
		if ( $rule->{type} eq 'required' ) {
			return $rule unless $result;
		} elsif ( $rule->{type} eq 'reject' ) {
			return $rule if $result;
		}
	}
	return;
}

1;
