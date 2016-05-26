package Config::SiteSync;
use strict;
use warnings;

sub new {
	my $class = shift;
	my $self = bless +{
		dir_roles => '/tmp/sitesync/config/roles',
		dir_nodes => '/tmp/sitesync/config/nodes',
		restrictions => +{
				path => +{
					source => [
						+{ type => 'required', pattern => '^/tmp/' },
						+{ type => 'required', pattern => '/$' },
						+{ type => 'reject'  , pattern => '\.\.' },
					],
					destination => [
						+{ type => 'required', pattern => '^/tmp' },
						+{ type => 'required', pattern => '/$' },
						+{ type => 'reject'  , pattern => '\.\.' },
					],
				}
			},
	}, $class;
	return $self;
}

1;
