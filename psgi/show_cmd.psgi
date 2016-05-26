# PSGI application
use strict;
use warnings;

use File::Spec;
use File::Basename;
use local::lib File::Spec->catdir(dirname(__FILE__), 'extlib');
use lib File::Spec->catdir(dirname(__FILE__), '../modules');
use RsyncConfig;
use Config::SiteSync;
use Plack::Request;
use Data::Dumper;

my $application = sub {
	my $env = shift;
	
	my $req = Plack::Request->new($env);
	
	my $id   = $req->parameters->{id};
	my $cf = Config::SiteSync->new;
	my $c = RsyncConfig->new;
	
	my $directory = $cf->{dir_roles};
	my $filename  = "${id}.json";
	my $path = "$directory/$filename";
	
	my ($header, $message, $fh);
	if ( not -f $path ) {
		$header  = [500,['Content-Type' => 'text/plain']];
		my $return_c = +{
			status => 'NG',
			path   => $path,
			error  => "Role File Not Exists. path='$path'"
		};
		$message = JSON->new->pretty->canonical->utf8->encode($return_c);
	} elsif ( not defined $path or length $path == 0 ) {
		$header  = [500,['Content-Type' => 'text/plain']];
		my $return_c = +{
			status => 'NG',
			path   => $path,
			error  => "Unknown path. path='$path'"
		};
		$message = JSON->new->pretty->canonical->utf8->encode($return_c);
	} elsif ( not open($fh, '<', $path) ) {
		$header  = [500,['Content-Type' => 'text/plain']];
		my $return_c = +{
			status => 'NG',
			path   => $path,
			error  => "File Open Failed. $!"
		};
		$message = JSON->new->pretty->canonical->utf8->encode($return_c);
	} else {
		local $/;
		my $json = do { local $/ = undef; <$fh>; };
		my $c = RsyncConfig->from_json($json);
		my $cmd = $c->build_cmdopts;
		$cmd =~ s/\\\n/ /g;
		$header  = [200,['Content-Type' => 'text/plain']];
		my $return_c = +{
			status   => 'OK',
			path     => $path,
			command  => "rsync $cmd",
		};
		$message = JSON->new->pretty->canonical->utf8->encode($return_c);
	}
	return sub {
		my $resp = shift;
		my $writer = $resp->($header);
		$writer->write($message);
		$writer->close;
	};
};

$application; # pass procedure.


