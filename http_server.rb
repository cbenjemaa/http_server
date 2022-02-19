require 'socket'

server  = TCPServer.new('0.0.0.0', ENV["SERVER_PORT"])

loop {
  client  = server.accept
  request = client.readpartial(2048)
  
  method, path, version = request.lines[0].split

  puts "#{method} #{path} #{version}"

  if path == "/healthcheck"
    #Adding HTTP Headers to fix curl issue
    #curl: (1) Received HTTP/0.9 when not allowed
    client.write("HTTP/1.1 200\r\n")
    client.write("Content-Type: text/html\r\n")
    client.write("\r\n")
    client.write("OK")
  else
    client.write("HTTP/1.1 200\r\n")
    client.write("Content-Type: text/html\r\n")
    client.write("\r\n")
    client.write("Well, hello there!")
  end

  client.close
}
