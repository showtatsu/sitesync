package RsyncConfig;
use strict;
use warnings;
use Data::Dumper;
use JSON qw();
use Tie::IxHash;

our %TYPES = (
	flag      => 0,
	bool      => 1,
	int       => 2,
	path      => 4,
	path_wild => 8,
);

sub flag      { $TYPES{flag}; }
sub bool      { $TYPES{bool}; }
sub integer   { $TYPES{int} ; }
sub path      { $TYPES{path}; }
sub path_wild { $TYPES{path_wild}; }

tie our %FIELDS, "Tie::IxHash", (
	id          => +{ default => undef },
	name        => +{ default => undef },
	memo        => +{ default => undef },
	options     => +{ default => []    },
	source      => +{ default => undef },
	destination => +{ default => undef },
);

our %OPTIONS = (
	'archive'  => +{ key => '-a'          },
	'delete'   => +{ key => '--delete'    },
	'update'   => +{ key => '--update'    },
	'compress' => +{ key => '-z'          },
	'relative' => +{ key => '-R'          },
	'dry-run'  => +{ key => '-n'          },
	'inplace'  => +{ key => '--inplace'   },
	'delete_excluded' => +{ key => '--delete-excluded' },
	'rsh'      => +{ key => '--rsh',     rewrite => '="%s"', parse => qr/^--rsh=\"(.+)\"$/     },
	'bwlimit'  => +{ key => '--bwlimit', rewrite => '=%s'  , parse => qr/^--bwlimit=([0-9]+)$/ },
	'exclude'  => +{ key => '--exclude', rewrite => '="%s"', parse => qr/^--exclude=(.+)$/     },
	'include'  => +{ key => '--include', rewrite => '="%s"', parse => qr/^--include=(.+)$/     },
);


sub new {
	my $class = shift;
	my %args  = @_;

	my $self = bless +{
			id          => undef,
			name        => undef,
			memo        => undef,
			options     => [],
			source      => undef,
			destination => undef,
		}, $class;
	foreach my $k ( keys %FIELDS ) {
		$self->{$k} = $args{$k} if defined $args{$k};
	}
	return $self;
}


sub build_cmdopts {
	my $self = shift;
	my @arguments;
	foreach my $option ( @{$self->{options}} ) {
		if (defined $option->{option} and length $option->{option} > 0) {
			push(@arguments, $option->{option});
		}
	}
	my $src = $self->{source};
	my $dst = $self->{destination};
	return join(" \\\n", @arguments, $src, $dst);
}

sub from_json {
	my $self = shift;
	my ($json) = @_;
	if ($self eq __PACKAGE__) {
		$self = __PACKAGE__->new;
	} elsif (not defined $json) {
		$json = $self;
		$self = __PACKAGE__->new;
	}
	my $object = JSON->new->utf8->decode( $json );
	foreach my $k ( keys %FIELDS ) {
		$self->{$k} = $object->{$k} if (defined $object->{$k});
	}
	return $self;
}

sub to_json {
	my $self = shift;
	my %object = %$self;
	my $json = JSON->new->pretty->canonical->utf8->encode( \%object );
	return $json;
}


=head3 set_from_query ( query_key, query_value )
APIからのPOST入力を使用して設定値を更新します。
=cut

sub set_from_query {
	my $self = shift;
	my ($apik, $apiv) = @_;

	return $self->_set_err("set_query: key is not defined.") unless(defined $apik);
	return $self->_set_err("set_query: va;ie is not defined. key=[$apik]") unless (defined $apiv);
	our %OPTIONS;
	my $m    = $OPTIONS{$apik};
	my $cmdk = $m->{key};
	my $a;
	if(my $rewrite = $m->{rewrite}) {
		$a = "$cmdk" . sprintf($rewrite, $apiv);
		print Dumper "OKOK", $rewrite, $apiv;
	} elsif ($apiv) {
		$a = "$cmdk";
		print Dumper "OK", $apiv;
	} else {
		$a = "";
	}
	my $option = +{};
	$option->{key}    = $apik;
	$option->{value}  = $apiv;
	$option->{option} = $a;
	push(@{$self->{options}}, $option);
	return $option;
}


=head3 set_from_cmdopt ( cmdline_opt )
rsyncコマンドラインオプション値を入力として設定値を更新します。
=cut

sub set_from_cmdopt {
	my $self = shift;
	my ($cmdopt) = @_;
	my ($cmdk, $cmdv) = split(/=/, $cmdopt, 2);
	return unless (defined $cmdk);
	our %OPTIONS;
	foreach my $apik (keys %OPTIONS) {
		my $m = $OPTIONS{$apik};
		next unless $cmdk eq $m->{key};
		if (not defined $m->{parse}) {
			my $o = +{
				key    => $apik,
				value  => 1,
				option => $cmdopt,
			};
			push(@{$self->{options}}, $o);
			return $o;
		} elsif( $cmdopt =~ m/$m->{parse}/ ) {
			my $o = +{
				key    => $apik,
				value  => $1,
				option => $cmdopt,
			};
			push(@{$self->{options}}, $o);
			return $o;
		} else {
			return;
		}
	}
	return;
}

sub _set_err {
	my $self = shift;
	$self->{lasterror} = shift;
	return;
}

sub _unset_err {
	my $self = shift;
	delete $self->{lasterror};
	return;
}

1;
