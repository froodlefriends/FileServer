require 'socket'      # Sockets are in standard library

hostname = 'localhost'
@ds_port = 2000
@timestamp = 0
@lock = 0

msg = 'OPEN:'
msg += "test2.txt\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^OK:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    @lock = message[/^LOCK:(.*)\n/,1]
    p 'lock'
    p @lock
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    p 'Has file successfully been opened?:'
    puts message
    s.close
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end


# ********* READ ***************
msg = 'READ:'
msg += "test2.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^READ:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    msg = 'READ:'
    msg += "test2.txt\n"

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    f_msg = s.gets
    s.close
    p 'Has file successfully been read?:'
    puts message
    p f_msg
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end

# ************ WRITE ***************
msg = 'WRITE:'
msg += "test2.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^OK:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    fserver = message[/^PM:(.*)\n/,1]
    f_server = fserver.to_i
    s.close               # Close the socket when done

    msg = 'WRITE:'
    msg += "test2.txt\n"
    msg += 'MESSAGE: This file was last updated on '
    t_stamp = Time.new
    msg += t_stamp.inspect
    t_s = t_stamp.to_i
    msg += " which is #{t_s}"

    s = TCPSocket.open(hostname, f_server)
    p msg
    s.puts msg
    message = s.gets
    s.close
    p 'Has file successfully been written to?:'
    puts message
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end


# ********* READ ***************
msg = 'READ:'
msg += "test2.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^READ:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    msg = 'READ:'
    msg += "test2.txt\n"

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    f_msg = s.gets
    s.close
    p 'Has file successfully been read?:'
    puts message
    p f_msg
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end

# *********** CLOSE *****************
msg = 'CLOSE:'
msg += "test2.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^CLOSE:(.*)\n/,1]
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    msg = 'CLOSE:'
    msg += "test2.txt\n"

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    s.close
    p 'Has file successfully been closed?:'
    puts message
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end



msg = 'OPEN:'
msg += "test.txt\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^OK:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    @lock = message[/^LOCK:(.*)\n/,1]
    p 'lock'
    p @lock
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    p 'Has file successfully been opened?:'
    puts message
    s.close
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end


# ********* READ ***************
msg = 'READ:'
msg += "test.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^READ:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    msg = 'READ:'
    msg += "test.txt\n"

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    f_msg = s.gets
    s.close
    p 'Has file successfully been read?:'
    puts message
    p f_msg
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end

# ************ WRITE ***************
msg = 'WRITE:'
msg += "test.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^OK:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    fserver = message[/^PM:(.*)\n/,1]
    f_server = fserver.to_i
    s.close               # Close the socket when done

    msg = 'WRITE:'
    msg += "test.txt\n"
    msg += 'MESSAGE: This file was last updated on '
    t_stamp = Time.new
    msg += t_stamp.inspect
    t_s = t_stamp.to_i
    msg += " which is #{t_s}"

    s = TCPSocket.open(hostname, f_server)
    p msg
    s.puts msg
    message = s.gets
    s.close
    p 'Has file successfully been written to?:'
    puts message
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end


# ********* READ ***************
msg = 'READ:'
msg += "test.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^READ:(.*)\n/,1]
    message = s.gets
    @timestamp = message[/^TS:(.*)\n/,1]
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    msg = 'READ:'
    msg += "test.txt\n"

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    f_msg = s.gets
    s.close
    p 'Has file successfully been read?:'
    puts message
    p f_msg
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end

# *********** CLOSE *****************
msg = 'CLOSE:'
msg += "test.txt\n"
msg += "TS:#{@timestamp}\n"

s = TCPSocket.open(hostname, @ds_port)

s.puts msg
message = s.gets

case message
  when /OK:.*\n/
    fname = message[/^CLOSE:(.*)\n/,1]
    message = s.gets
    fserver = message[/^SLIST:(.*)\n/,1]
    tempfs = fserver
    begin
      fserver = tempfs
      tempfs = s.gets.chomp
    end while tempfs !=''

    f_server = fserver.to_i

    s.close               # Close the socket when done

    msg = 'CLOSE:'
    msg += "test.txt\n"

    s = TCPSocket.open(hostname, f_server)
    s.puts msg
    message = s.gets
    s.close
    p 'Has file successfully been closed?:'
    puts message
  when /ERROR:.*\n/
    msg = message[/^ERROR:(.*)\n/,1]
    puts msg
    s.close
  else
    p 'Unexpected Error has occurred'
    s.close
end


p 'The End'



