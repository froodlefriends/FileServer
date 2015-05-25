require 'socket'
require 'thread'
require 'fileutils'
require 'base64'

class Pool

  def initialize(port, size)

    # Size thread pool and Queue for storing clients
    @ds_port = 2000
    @folder = "FS#{port}"
    @size = size
    @jobs = Queue.new
    @isPM = 0
    @own_port = port

    if !File.directory?("#{@folder}")
      Dir.mkdir "#{@folder}"
    end
    @list = Dir.entries "#{@folder}"
    p @list[2]
    p @list.length

    ds_msg = "JOIN:#{port}\nLIST:"
    i=2
    while i<@list.length
      ds_msg += "#{@list[i]}\n"
      i+=1
    end
    ds_msg += "\n"
    s = TCPSocket.open('localhost', @ds_port)
    loop do
      s.puts ds_msg
      message = s.gets
      puts message
      case message
        when /^ACK: .*\n/
          msg = s.gets
          mp_msg = msg[/^ISPM:(.*)\n/,1]    #sets whether is Primary Manager or not
          @isPM = mp_msg.to_i
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

    f = File.open(path)
    @reply = "OK: #{fname}\n"
    client.puts("#{@reply}")

    #connected(client)
  end

  def close_file(client, msg)
    fname = msg[/CLOSE:(.*)\n/,1]
    puts "--#{fname}--"
    path = "#{@folder}/#{fname}"
    f = File.open(path)
    f.close()
    @reply = "OK: #{fname}\n"

    client.puts("#{@reply}")

    #connected(client)
  end

  def read_file(client, msg)
    fname = msg[/READ:(.*)\n/,1]
    puts "--#{fname}--"

    path = "#{@folder}/#{fname}"

    fmsg = File.read(path)

    @reply = "OK: #{fname}\n"
    @reply+= "MESSAGE: #{fmsg}\n"

    client.puts("#{@reply}")

  end

  # Writing to file. Need to check for RMs if are PM.
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

    if @isPM
      ds_msg = "REP:#{fname}"
      # Get list of replica managers
      s = TCPSocket.open('localhost', @ds_port)
      s.puts ds_msg
      msg = s.gets
      ack = msg[/^OK:(.*)\n/,1]
      msg = s.gets
      t_list = msg[/^RMLIST:(.*)\n/,1]

      begin
        rm_port = t_list.to_i
        p rm_port
        if(rm_port != @own_port)
          p 'not own port, replicating'
          rm_msg = "WRITE:#{fname}\nMESSAGE:#{w_msg}\n"
          rm_s = TCPSocket.open('localhost', rm_port)

          rm_s.puts rm_msg
          message = rm_s.gets
          rm_s.close
        end
        t_list = s.gets.chomp
      end while t_list != ''
      s.close()
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
s = Server.new(2002)