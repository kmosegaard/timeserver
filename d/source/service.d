import std.container : Array;
import std.socket : Address, InternetAddress, ProtocolType, Socket, SocketSet, SocketShutdown, TcpSocket, UdpSocket;

interface IServiceSocket
{
    @property ProtocolType protocolType();
    @property Socket socket();
}

class ServiceSocket(T : Socket, ProtocolType PROTOCOLTYPE) : IServiceSocket
{
private:
    const ProtocolType _protocolType = PROTOCOLTYPE;
    T _socket;

public:
    @property ProtocolType protocolType()
    {
        return this._protocolType;
    }

    @property Socket socket()
    {
        return this._socket;
    }

    this(ushort port = 37)
    {
        this._socket = new T();
        auto internetAddress = new InternetAddress(port);

        this._socket.bind(internetAddress);
        this._socket.blocking = false;

        if (protocolType == ProtocolType.TCP)
            this._socket.listen(10);
    }
}

alias TcpServiceSocket = ServiceSocket!(TcpSocket, ProtocolType.TCP);
alias UdpServiceSocket = ServiceSocket!(UdpSocket, ProtocolType.UDP);

class TimeService()
{
private:
    Array!IServiceSocket _subscribers;
    SocketSet _socketSet = new SocketSet();

    pragma(inline):
    void handleTcpConnection(Socket socket)
    {
        Socket sn = null;
        scope (exit) sn.close();
        scope (failure) if (sn) sn.close();

        // Accept incoming connection
        sn = socket.accept();
        assert(sn.isAlive);
        assert(socket.isAlive);

        // Send timestamp
        sn.send(getRfc868Timestamp());

        // Wait for users connection to close.
        sn.shutdown(SocketShutdown.BOTH);
    }

    pragma(inline):
    void handleUdpConnection(Socket socket)
    {
        Address sender;
        ubyte[1] payload;

        // Receive datagram from sender
        socket.receiveFrom(payload, sender);

        // Send timestamp
        socket.sendTo(getRfc868Timestamp(), sender);
    }

public:
    @property size_t subscriberCount() { return this._subscribers.length; };

    void subscribe(IServiceSocket socket)
    {
        import std.algorithm.searching : any;
        
        if (any!(a => a == socket)(this._subscribers[])) return;
        this._subscribers.insert(socket);
    }

    void unsubscribe(IServiceSocket socket)
    {
        import std.algorithm.searching : find;

        if (this._subscribers.length == 0) return;
        auto range = find!(a => a == socket)(this._subscribers[]);   
        this._subscribers.linearRemove(range);
    }

    void run()
    {
        foreach (socket; this._subscribers)
        {
            this._socketSet.add(socket.socket);
        }

        Socket.select(_socketSet, null, null);

        foreach (socket; this._subscribers)
        {
            if (this._socketSet.isSet(socket.socket))
            {        
                switch (socket.protocolType)
                {
                    case ProtocolType.TCP:
                        handleTcpConnection(socket.socket);
                        break;
                    case ProtocolType.UDP:
                        handleUdpConnection(socket.socket);
                        break;
                    default:
                        break;
                }
            }
        }

        this._socketSet.reset();
    }
}

ubyte[] getRfc868Timestamp()
{
    import std.bitmanip : write;
    import std.conv : to;
    import std.datetime : Clock, UTC;
    
    const uint secondsToEpoch = 2_208_988_800;
    auto currentTime = to!(uint)(Clock.currTime(UTC()).toUnixTime() + secondsToEpoch);
    ubyte[] buffer = [0, 0, 0, 0, 0, 0, 0, 0];
    buffer.write!uint(currentTime, 0);
    return buffer;
}
