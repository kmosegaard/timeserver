#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use IO::Socket::INET;

my %options=();
getopts("hut", \%options);

if ($options{h})
{
	print "\n";
	print "Usage: client.pl [switches] [ip] [port]\n";
	print "  -h \t\tPrints help.\n";
	print "  -u \t\tSend UDP request.\n";
	print "  -t \t\tSend TCP request.\n";
	print "\n";
	exit;
}

my ($host, $port) = @ARGV;
if (not defined $host) 
{
	print "Host is not defined!\n";
	exit;
}

if (not defined $port) 
{
	print "Using default port (37).\n";
	$port = 37;
}

my $seconds_since_1900_upto_epoch = 2208988800;

if ($options{t}) 
{
	my $tcp_socket = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Proto => "tcp");
	die "Can't connect to $host:$port.\n" unless $tcp_socket;

	my $response = "";
	$tcp_socket->recv($response, 4);

	my $time = localtime(unpack("N*", $response) - $seconds_since_1900_upto_epoch); 
	print "Server sent timestamp: $time\n";

	$tcp_socket->close();
}

if ($options{u}) 
{
	my $udp_socket = IO::Socket::INET->new(PeerHost => $host, PeerPort => $port, Proto => "udp");
	die "Can't create UDP socket to $host:$port.\n" unless $udp_socket;

	$udp_socket->send("");

	my $response;
	$udp_socket->recv($response, 4);

	my $time = localtime(unpack("N*", $response) - $seconds_since_1900_upto_epoch); 
	print "Server sent timestamp: $time\n";

	$udp_socket->close();
}
