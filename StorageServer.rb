require 'socket'
require 'thread'
require 'fileutils'


class Pool

  def initialize(port, size)

    # Size thread pool and Queue for storing clients
    ds_port = 2000
    @folder = "FS#{port}"
    @size = size
    @jobs = Queue.new
    @isPM = 0

    if !File.directory?("#{@folder}")
      Dir.mkdir "#{@folder}"
    end
    @list = Dir.entries "#{@folder}"
    p @list

    ds_msg = "JOIN: #{port}\nLIST: #{@list}\n"
    s = TCPSocket.open('localhost', ds_port)
    loop do
        s.puts ds_msg
        message = s.gets
        puts message
        case message
          when /ACK .*\n/
            msg = client.gets
            @isPM = msg[/PM:(.*)\n/,1]
            break
        end
    end


    s.close



    # Creating our pool of threads
    @pool = Array.new(@size) do |i|
      Thread.new do
        Thread.current[:id] = i

        catch(:exit) do
          loop do
            worker(i)
          end
        end

      end
    end

  end

  def worker(i)
    client = @jobs.pop
    sleep rand(i)                 # simulating different work loads
    message = client.gets
    puts message

    case message
      when /HELO .*\n/
        helo(client, message)
      when /JOIN_CHATROOM:.*\n/
        join_cr(client, message)
      when /OPEN:.*\n/
        open_file(client, message)
      when /CLOSE:.*\n/
        close_file(client, message)
      when /READ:.*\n/
        read_file(client, message)
      when /WRITE:.*\n/
        write_file(client, message)
      when /KILL_SERVICE.*\n/
        kill_server
      else
        client.puts("ERROR: Invalid command line\n")
        client.close
    end
  end

  def helo(client, msg)
    @ipAddr = client.peeraddr[3].to_s
    @reply = "#{msg}IP: "
    @reply += "lg12l15.scss.tcd.ie" #{@ipAddr}"
    @reply += "\nPort: #{@port}"
    @reply += "\nStudent Number: 98609335\n"
    client.puts("#{@reply}")
  end

  def open_file(client, msg)
    fname = msg[/OPEN:(.*)\n/,1]
    puts "--#{fname}--"

    path = "#{@folder}/#{fname}"

    #Check if file in directory

    f = File.open(path)
    p 'done'
    @reply = "OK: #{fname}\n"
    client.puts("#{@reply}")

    #connected(client)
  end

  def close_file(client, msg)
    fname = msg[/CLOSE:(.*)\n/,1]
    puts "--#{fname}--"
    path = "#{@folder}/#{fname}"
    File.close(path)

    @reply = "OK: #{fname}\n"

    client.puts("#{@reply}")

    #connected(client)
  end

  def read_file(client, msg)
    fname = msg[/READ:(.*)\n/,1]
    puts "--#{fname}--"

    path = "#{@folder}/#{fname}"

    fmsg = File.read(path)
    puts fmsg
    # file = File.open(fname, 'wb')
    # file.print("test shorter ")
    # file.close()
    p 'done'

    @reply = "OK: #{fname}\n"
    @reply+= "MESSAGE: #{fmsg}\n"

    puts @reply
    client.puts("#{@reply}")

    #connected(client)
  end

  def write_file(client, msg)
    fname = msg[/WRITE:(.*)\n/,1]
    puts "--#{fname}--"
    path = "#{@folder}/#{fname}"

    msg = client.gets
    w_msg = msg[/MESSAGE:(.*)\n/,1]
    puts w_msg

    #puts w_msg
    file = File.open(path, 'wb')
    file.print(w_msg)
    file.close()
    p 'done'

    if @isPM
      p 'must get list to replicate to!'
    end
    @reply = "OK: #{fname}\n"
    client.puts("#{@reply}")

    #connected(client)
  end

  def kill_server
    abort('You just killed me!')
  end

  def unknown(client, msg)
    @reply = "You sent me #{msg}"
    client.puts("#{@reply}")
  end

  # ### Work scheduling
  def schedule(waitingClient)
    @jobs << waitingClient
  end

  # ### Port number to send
  def serverDetails( port )
    @port = port
  end

end

class Server

  # Open connection and create Pool instance
  def initialize( port )
    @server = TCPServer.open( port )
    puts "Server started on port #{port}"
    @serverPool = Pool.new(port, 10)
    @serverPool.serverDetails( port )
    run
  end

  # Accept clients and put on queue
  def run
    loop{
      @client = @server.accept
      @serverPool.schedule(@client)
    }
  end

end

port = ARGV.shift
#s = Server.new(port)
s = Server.new(2001)