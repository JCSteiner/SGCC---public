# Socks Server. handles socks 4/5 proxies. 
# modification from: https://github.com/p3nt4/Invoke-SocksProxy/blob/master/ReverseSocksProxyHandler.py

############################## LOADS DEPENDENCIES #############################
import socket
import sys
import _thread
import time
import ssl
import queue

# main function. used to start the server
def main(handlerPort, proxyPort, certificate, privateKey):
    # handlerPort - the port that we will accept connections on from our clients
    # proxyPort   - the port that we will be taking in proxy traffic from attacker machines
    # certificate - what we will use to encrypt the TLS traffic
    # privateKey  - also used for TLS traffic
    

    # starts a new thread, running the server function with the specified args
    _thread.start_new_thread(server, (handlerPort, proxyPort, certificate, privateKey))

    # sleeps infinitely while the other thread is running
    while True:
        time.sleep(60)

# starts up our socks handler server
def handler_server(q, handlerPort, certificate, privateKey):

    # establishes our TLS v1.2 server
    context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
    context.load_cert_chain(certificate, privateKey)
    try:

        # binds to our port on this machine
        dock_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        dock_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        dock_socket.bind(('', int(handlerPort)))
        dock_socket.listen(5)
        print("Handler listening on: " + handlerPort)

        while True:
            try:
                
                # accepts connections coming in
                clear_socket, address = dock_socket.accept()
                client_socket = context.wrap_socket(clear_socket, server_side=True)
                print("Reverse Socks Connection Received: {}:{}".format(address[0], address[1]))
                try:

                    # data handling code
                    data = b""
                    while (data.count(b'\n') < 3):
                        data_recv = client_socket.recv()
                        data += data_recv
                    
                    client_socket.send(
                        b"HTTP/1.1 200 OK\nContent-Length: 999999\nContent-Type: text/plain\nConnection: Keep-Alive\nKeep-Alive: timeout=20, max=10000\n\n")
                    
                    q.get(False)
                except Exception as e:
                    pass

                q.put(client_socket)
            except Exception as e:
                print(e)
                pass
    except Exception as e:
        print(e)
    finally:
        dock_socket.close()

# if we detect a connection, then we send our HELLO message
def get_active_connection(q):
    try:
        client_socket = q.get(block=True, timeout=1000)
    except:
        print('No Reverse Socks connection found')
        return None
    try:
        client_socket.send(b"HELLO")
    except:
        return get_active_connection(q)
    return client_socket

# the server manager function
def server(handlerPort, proxyPort, certificate, privateKey):
    # handlerPort - the port that we accept client (implant) connections from
    # proxyPort   - the port that we will take attacker machine connections from
    # certificate - used for TLS
    # privateKey  - used for TLS

    # initializes the handler server function as a thread
    q = queue.Queue()
    _thread.start_new_thread(handler_server, (q, handlerPort, certificate, privateKey))


    try:
        # initializes a socket connection on the current ip address
        dock_socket2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        dock_socket2.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        dock_socket2.bind(('', int(proxyPort)))
        dock_socket2.listen(5)
        print("Socks Server listening on: " + proxyPort)


        while True:
            try:

                # takes proxy client connections
                client_socket2, address = dock_socket2.accept()
                print('Client Connection Recs')
                print("Socks Connection Received: {}:{}".format(address[0], address[1]))
                
                # attempts to send our HELLO message to whoever connects
                client_socket = get_active_connection(q)
                # if we have a reverse socks connection
                if client_socket == None:
                    client_socket2.close()

                # sends our traffic to the connected implant
                _thread.start_new_thread(forward, (client_socket, client_socket2))
                _thread.start_new_thread(forward, (client_socket2, client_socket))
            except Exception as e:
                print(e)
                pass
    except Exception as e:
        print(e)
    finally:
        dock_socket2.close()

# forwards TLS traffic
def forward(source, destination):

    # while there is stuff to send, sends all the traffic straight through to the implant
    try:
        string = ' '
        while string:
            string = source.recv(1024)
            if string:
                destination.sendall(string)
            else:
                source.shutdown(socket.SHUT_RD)
                destination.shutdown(socket.SHUT_WR)
    except:
        try:
            source.shutdown(socket.SHUT_RD)
            destination.shutdown(socket.SHUT_WR)
        except:
            pass
        pass


# executes the proxy server
if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage:{} <handlerPort> <proxyPort> <certificate> <privateKey>".format(sys.argv[0]))
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])