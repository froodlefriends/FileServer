require 'socket'      # Sockets are in standard library

hostname = 'localhost'
port = 2001

  msg = 'OPEN:'
  msg += "test.txt\n"

  s = TCPSocket.open(hostname, port)

  s.puts msg
  message = s.gets
  puts message

  s.close               # Close the socket when done

  msg = 'READ:'
  msg += "test.txt\n"

  s = TCPSocket.open(hostname, port)

  s.puts msg
  message = s.gets
  f_msg = s.gets
  puts message
  p f_msg

  s.close

  msg = 'WRITE:'
  msg += "test.txt\n"
  msg += 'MESSAGE: This file was last updated on '

  t_stamp = Time.new

  msg += t_stamp.inspect

  s = TCPSocket.open(hostname, port)

  s.puts msg
  message = s.gets
  puts message

  s.close               # Close the socket when done

  msg = 'READ:'
  msg += "test.txt\n"

  s = TCPSocket.open(hostname, port)

  s.puts msg
  message = s.gets
  f_msg = s.gets
  puts message
  p f_msg

  s.close

  msg = 'CLOSE:'
  msg += "test.txt\n"

  s = TCPSocket.open(hostname, port)

  s.puts msg
  message = s.gets
  puts message

  s.close

  p 'The End'