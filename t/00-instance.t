#!/bin/env perl

use strict;
use warnings;

use FindBin;
use lib("${FindBin::Bin}/../modules");
use Test::More;
use RsyncConfig;

my $c = RsyncConfig->new(
	id => 1, name => 'mysite#production', memo => 'mysite config.',
	source => '/tmp/nas/',
	destination => '/tmp/site'
	);
isa_ok( $c, "RsyncConfig" );

$c->set_from_cmdopt("-a");
$c->set_from_cmdopt("--delete");
$c->set_from_cmdopt("--update");
$c->set_from_cmdopt("--include=\"/share/js/static\"");
$c->set_from_cmdopt("--exclude=\"/share/css\"");
$c->set_from_cmdopt("--exclude=\"/share/js\"");

print "===================\n";
print $c->to_json;
print "\n===================";

print "===================\n";
print $c->build_cmdopts;
print "\n===================";

done_testing;

