require 'socket'
require 'uri'

HOST = 'localhost'
PORT = 8000
DOC_ROOT = Dir.pwd

server = TCPServer.new(HOST, PORT)
puts "Serving #{DOC_ROOT} on http://#{HOST}:#{PORT}"

loop do
  socket = server.accept

  request_line = socket.gets
  next unless request_line

  _, full_path, = request_line.split
  path = URI.decode_www_form_component(full_path.split('?').first)
  path = path.gsub(%r{(\.\./)+}, '') # basic path traversal protection

  file_path = File.join(DOC_ROOT, path)
  file_path = File.join(file_path, 'index.html') if File.directory?(file_path)

  if File.file?(file_path)
    ext = File.extname(file_path)
    mime = {
      '.html' => 'text/html',
      '.css' => 'text/css',
      '.js' => 'application/javascript',
      '.png' => 'image/png',
      '.jpg' => 'image/jpeg',
      '.gif' => 'image/gif'
    }[ext] || 'application/octet-stream'

    body = File.binread(file_path)
    socket.print "HTTP/1.1 200 OK\r\nContent-Type: #{mime}\r\nContent-Length: #{body.bytesize}\r\n\r\n"
    socket.write body
  else
    socket.print "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nFile not found"
  end

  socket.close
end
