# PSGI application
use strict;
use warnings;

use File::Spec;
use File::Basename;
use local::lib File::Spec->catdir(dirname(__FILE__), 'extlib');
use lib File::Spec->catdir(dirname(__FILE__), '../modules');
use RsyncConfig;
use Restrict;
use Config::SiteSync;
use Plack::Request;
use Data::Dumper;

sub validate {
	my ($cf,$rc) = @_;
	my $r = $cf->{restrictions};
	my $catch;
	if ($catch = Restrict->new( $r->{path}->{source} )->check( $rc->{source} )) {
		return $catch;
	} elsif ($catch = Restrict->new( $r->{path}->{destination} )->check( $rc->{destination} )) {
		return $catch;
	}
	return;
}


my $application = sub {
	my $env = shift;
	
	my $req = Plack::Request->new($env);
	
	my $id   = $req->parameters->{id};
	my $name = $req->parameters->{name};
	my $memo = $req->parameters->{memo};
	my $src  = $req->parameters->{source};
	my $dst  = $req->parameters->{destination};
	my $opts = $req->parameters->{options};
	$id = "dummy-001" unless ($id);
	my $cf = Config::SiteSync->new;
	my $c = RsyncConfig->new;
	
	$c->{id}          = $id;
	$c->{name}        = $name;
	$c->{source}      = $src;
	$c->{destination} = $dst;
	$c->{memo}        = $memo;
	$c->set_from_query("archive", 1);
	
	my $vl = validate($cf, $c);
	
	my $directory = $cf->{dir_roles};
	my $filename  = "${id}.json";
	my $path = "$directory/$filename";
	
	my ($header, $message, $fh);
	if ( $vl ) {
		$header  = [403, ['Content-Type' => 'text/plain']];
		my $return_c = +{
			status => 'NG',
			error  => "Config was rejected by restrictions. Rule: $vl->{type}, $vl->{pattern}",
		};
		$message = JSON->new->pretty->canonical->utf8->encode($return_c);
	} elsif ( -f $path ) {
		$header  = [500,['Content-Type' => 'text/plain']];
		my $return_c = +{
			status => 'NG',
			path   => $path,
			error  => "Role File Already Exists. path='$path'"
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
	} elsif ( not open($fh, '>', $path) ) {
		$header  = [500,['Content-Type' => 'text/plain']];
		my $return_c = +{
			status => 'NG',
			path   => $path,
			error  => "File Open Failed. $!"
		};
		$message = JSON->new->pretty->canonical->utf8->encode($return_c);
	} else {
		my $contents = $c->to_json;
		print $fh $contents;
		close $fh;
		$header  = [200,['Content-Type' => 'text/plain']];
		my $return_c = +{
			status => 'OK',
			path   => $path,
			contents => +{ %$c },
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


