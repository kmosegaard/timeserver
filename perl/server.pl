#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;
use IO::Select;
use IO::Socket;

my %options=();
getopts("h", \%options);

if ($options{h})
{
	print "\n";
	print "Usage: client.pl [switches] [port]\n";
	print "  -h \t\tPrints help.\n";
	print "\n";
	exit;
}

my ($port) = @ARGV;
if (not defined $port) 
{
	print "Using default port (37).\n";
	$port = 37;
}

my $seconds_since_1900_upto_epoch = 2208988800;
$| = 1;

my $tcp_socket = IO::Socket::INET->new(LocalHost => '0.0.0.0',
		  																 LocalPort => $port,
																			 Proto => "tcp",
																			 Listen => 5,
																			 Reuse => 1);
die "Can not create socket TCP socket.\n" unless $tcp_socket;

my $udp_socket = IO::Socket::INET->new(LocalPort => $port, Proto => "udp");
die "Can not create socket UDP socket.\n" unless $udp_socket;

my $io_select = IO::Select->new();
$io_select->add($tcp_socket);
$io_select->add($udp_socket);

while (my @ready = $io_select->can_read)
{
	foreach my $fh (@ready)
	{
		if ($fh == $tcp_socket)
		{
			# TCP Socket
			my $tcp_client_socket = $tcp_socket->accept();

			my $tcp_client_host = $tcp_client_socket->peerhost(); 
			my $tcp_client_port = $tcp_client_socket->peerport();

			print "Client ($tcp_client_host:$tcp_client_port) connected.\n";

			my $time = pack("N*", time() + $seconds_since_1900_upto_epoch);

			$tcp_client_socket->send($time);
			$tcp_client_socket->shutdown(1);
		}
		elsif ($fh == $udp_socket)
		{
			# UDP Socket
	  	my $message;
			$udp_socket->recv($message, 0);

			my $udp_client_host = $udp_socket->peerhost(); 
			my $udp_client_port = $udp_socket->peerport();

			print "Client ($udp_client_host:$udp_client_port) connected.\n";

			my $time = pack("N*", time() + $seconds_since_1900_upto_epoch);
			$udp_socket->send($time);	
		}
		else
		{
			close($fh);
		}
	}
}


