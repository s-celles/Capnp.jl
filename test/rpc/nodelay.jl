# Tests for the TCP_NODELAY transport option.
# Cap'n Proto RPC exchanges many small messages, so Nagle's algorithm is
# disabled by default on TCP sockets, matching the reference implementation.

using Test
using Capnp
using Capnp.RPC
using Sockets

# Read TCP_NODELAY back from the kernel. Only used on Unix, where IPPROTO_TCP
# is 6 and TCP_NODELAY is 1 on every supported platform.
function read_tcp_nodelay(socket)
    fd = Base._fd(socket)
    value = Ref{Cint}(0)
    len = Ref{Cuint}(sizeof(Cint))
    rc = ccall(:getsockopt, Cint, (Cint, Cint, Cint, Ptr{Cint}, Ptr{Cuint}), Base.cconvert(Cint, fd), 6, 1, value, len)
    rc == 0 || error("getsockopt(TCP_NODELAY) failed: $(Libc.strerror(Libc.errno()))")
    return value[] != 0
end

@testset "TCP_NODELAY" begin
    @testset "set_tcp_nodelay!" begin
        listener = Sockets.listen(Sockets.IPv4("127.0.0.1"), 0)
        port = Int(Sockets.getsockname(listener)[2])
        try
            socket = Sockets.connect("127.0.0.1", port)
            try
                @test RPC.set_tcp_nodelay!(socket, true)
                @test RPC.set_tcp_nodelay!(socket, false)
                @test RPC.set_tcp_nodelay!(listener, true)

                if Sys.isunix()
                    RPC.set_tcp_nodelay!(socket, true)
                    @test read_tcp_nodelay(socket)
                    RPC.set_tcp_nodelay!(socket, false)
                    @test !read_tcp_nodelay(socket)
                end
            finally
                close(socket)
            end

            # Closed sockets and sockets without the option are left alone.
            closed = Sockets.connect("127.0.0.1", port)
            close(closed)
            @test !RPC.set_tcp_nodelay!(closed, true)
            @test !RPC.set_tcp_nodelay!(IOBuffer(), true)
        finally
            close(listener)
        end
    end

    @testset "TcpTransport applies the option" begin
        listener = Sockets.listen(Sockets.IPv4("127.0.0.1"), 0)
        port = Int(Sockets.getsockname(listener)[2])
        try
            default_transport = RPC.TcpTransport("127.0.0.1", port)
            try
                @test isopen(default_transport)
                Sys.isunix() && @test read_tcp_nodelay(default_transport.socket)
            finally
                close(default_transport)
            end

            nagling_transport = RPC.TcpTransport("127.0.0.1", port; nodelay = false)
            try
                @test isopen(nagling_transport)
                Sys.isunix() && @test !read_tcp_nodelay(nagling_transport.socket)
            finally
                close(nagling_transport)
            end
        finally
            close(listener)
        end
    end

    @testset "Options plumbing" begin
        @test RPC.DEFAULT_TCP_NODELAY
        @test RPC.ConnectionOptions().tcp_nodelay
        @test !RPC.ConnectionOptions(tcp_nodelay = false).tcp_nodelay
        @test RPC.ServerOptions().tcp_nodelay
        @test !RPC.ServerOptions(tcp_nodelay = false).tcp_nodelay
    end

    @testset "Server listener and accepted sockets" begin
        for nodelay in (true, false)
            server = RPC.Server("bootstrap"; options = RPC.ServerOptions(tcp_nodelay = nodelay))
            RPC.listen(server, "127.0.0.1", 0)
            port = Int(Sockets.getsockname(server.tcp_server)[2])
            RPC.serve_async(server)
            try
                Sys.isunix() && @test read_tcp_nodelay(server.tcp_server) == nodelay

                conn = RPC.connect("127.0.0.1", port, RPC.ConnectionOptions(tcp_nodelay = nodelay))
                try
                    # Wait for the accept loop to register the client.
                    for _ = 1:200
                        RPC.client_count(server) >= 1 && break
                        sleep(0.01)
                    end
                    @test RPC.client_count(server) == 1
                    if Sys.isunix()
                        accepted = RPC.get_clients(server)[1].transport.socket
                        @test read_tcp_nodelay(accepted) == nodelay
                    end
                finally
                    close(conn)
                end
            finally
                RPC.shutdown!(server)
            end
        end
    end
end
