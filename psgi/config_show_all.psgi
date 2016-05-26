# PSGI application : dbtest
use strict;
use warnings;
use File::Spec;
use File::Basename;
use local::lib File::Spec->catdir(dirname(__FILE__), 'extlib');
use lib File::Spec->catdir(dirname(__FILE__), '../modules');
use RsyncConfig;

my $application = sub {
    my $header = [200,['Content-Type' => 'text/plain']];
    my $c = RsyncConfig->new;
    $c->set_from_query("archive", 1);
    return sub {
        my $resp = shift;
	my $writer = $resp->($header);
	$writer->write( $c->to_json );
	$writer->close;
    };
};

$application; # pass procedure.


