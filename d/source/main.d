import service : TimeService, TcpServiceSocket, UdpServiceSocket;
import std.stdio : writeln;

void main(string[] args)
{
	auto timeService = new TimeService!();
	auto tcpSocket = new TcpServiceSocket();
	auto udpSocket = new UdpServiceSocket();

	timeService.subscribe(tcpSocket);
	timeService.subscribe(udpSocket);

	writeln("Starting time service.");
	while (true)
	{
		timeService.run();
	}
}
