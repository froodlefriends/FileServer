require 'socket'
require 'thread'
require 'base64'


class DirectoryFile

  @@currServs = Hash.new
  def initialize(name)
    @servers = Hash.new
    @name = name
    @lock = 0
    @ts = 0
    #@num_servers = 0
  end

  # NEED TO CHANGE THIS TO ADD PORT
  def add(s_port)
    @servers[s_port] = 1
  end

  def getList
    c = ''
    @servers.each do |pt, val|
      if val
        @@currServs[pt] = @servers[pt]
        p val
        c += "#{pt}\n"
      end
    end
    return c
  end

  def lock
    p @lock
    if @lock<1
      p 'lock is less than 1'
      @lock = 1
      t = Time.new
      @ts=t.to_i
      p 'ts:'
      p @ts
      p @lock
      return 1
    else
      p 'lock is greater than 1'
      return 0
    end
  end

  def acquire_lock
    if @lock < 1
      c_ts = Time.new
      curr_ts = c_ts.to_i
      if (@ts - curr_ts > 10)
        @ts = curr_ts         # Time out lock if another client waiting too long
        return 1
      end
    else
      return 0
    end
  end

  def updateTS(c_ts)
    p c_ts
    p @ts
    if (c_ts == @ts)
      n_ts = Time.new
      curr_ts = n_ts.to_i
      @ts = curr_ts
      return 1
    else
      return 0          # Means client has been timed out
    end
  end

  def get_ts
    return @ts
  end

  def unlock
    @lock = 0
  end

=begin
  def broadcast(ref, nickname, message)
    #puts 'broadcasting'
    #text = message.join('\n')
    msg = "CHAT:#{ref}\nCLIENT_NAME:#{nickname}"
    msg += "\nMESSAGE:#{message}\n\n"
    #puts "#{msg}"
    @cr_members.each do |nn, client|
      if client and nn != nickname
        client.puts msg
      end
    end
  end


  def leave(s_port)
    @servers[s_port] = 0
  end

  def check_members(nickname)
    c = 0
    @cr_members.each do |nn, client|
      if client and nn == nickname
        c += 1
        #leave(nn)
      end
    end
    return c
  end
=end
end


class Pool

  def initialize(port, size)

    # Size thread pool and Queue for storing clients
    @size = size
    @jobs = Queue.new

    @@liveServers = Hash.new
    @@files = Hash.new

    @pm = 0
=begin
    @@clientNum = 0
    @@roomNum = 0
    @@rooms = Hash.new
    @@c_rooms = Hash.new
    @@members = Hash.new
    @@memByID = Hash.new
=end

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
      when /JOIN:.*\n/
        join(client, message)
      when /LIST:.*\n/
        list(client, message)
      when /REP:.*\n/
        rep(client, message)
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

  def join(client, msg)
    s_port = msg[/^JOIN:(.*)\n/,1]
    msg = client.gets
    p s_port

    if @pm<1
      p 'about to become pm'
      s_pm = 1
      @pm = s_port
    else
      p 'not pm'
      s_pm = 0
    end
    p '@pm is'
    p @pm
    t_list = msg[/^LIST:(.*)\n/,1]
    #p t_list
    #p "#{t_list}"
    #@@liveServers[s_port].each do |f_name|
    begin
      if !@@files[t_list]
        @@files[t_list] = DirectoryFile.new(t_list)
      end
      @@files[t_list].add(s_port)

      t_list = client.gets.chomp
      p "#{t_list}"
    end while t_list != ''
    p 'here'
    @reply = "ACK: #{s_port}"
    @reply += "\nISPM:#{s_pm}\n"
    #@reply = Base64.encode(@reply)
    client.puts("#{@reply}")

  end

  def rep(client, msg)
    f_name = msg[/^REP:(.*)\n/,1]
    p f_name

    c = @@files[f_name].getList()
    p c
    p 'miracle!'
    @reply = "OK:#{f_name}\nRMLIST:#{c}\n"
    client.puts("#{@reply}")
  end

  def open_file(client, msg)
    fname = msg[/^OPEN:(.*)\n/,1]
    p fname
    @reply = ''
    if !@@files[fname]
      p 'no file'
      @reply = "ERROR:This file does not exist\n"
    else
      p 'yup file'
      c = ''
      lck = 0
      ts = 0
      proc = @@files[fname].lock()
      if proc > 0
        c = @@files[fname].getList()
      else
        t = Time.new
        ts=t.to_i
        while proc < 1
          p 'waiting for lock'
          sleep(2)
          proc = @@files[fname].acquire_lock
        end
      end
      lck = 1
      ts = @@files[fname].get_ts
      @reply = "OK:#{fname}\nTS:#{ts}\nLOCK:#{lck}\nSLIST:#{c}\n"
    end
    p @reply
    client.puts("#{@reply}")

  end

  def close_file(client, msg)
    fname = msg[/CLOSE:(.*)\n/,1]
    msg = client.gets
    ts = msg[/^TS:(.*)\n/,1]

    if !@@files[fname]
      @reply = "ERROR:This file does not exist\n"
    else
      if (@@files[fname].updateTS(ts))
        @@files[fname].unlock()
        c = @@files[fname].getList()
        @reply = "OK:#{fname}\nSLIST:#{c}\n"
      else
        @reply = "ERROR:Timeout Error\n"
      end
    end

    client.puts("#{@reply}")
  end

  def read_file(client, msg)
    fname = msg[/READ:(.*)\n/,1]
    msg = client.gets
    ts = msg[/^TS:(.*)\n/,1]
    ts = ts.to_i
    p ts
    if !@@files[fname]
      @reply = "ERROR:This file does not exist\n"
    else
      if (@@files[fname].updateTS(ts))
        p 'I here'
        c = @@files[fname].getList()
        p 'even here'
        ts = @@files[fname].get_ts
        p 'now should work'
        @reply = "OK:#{fname}\nTS:#{ts}\nSLIST:#{c}\n"
      else
        @reply = "ERROR:Timeout Error\n"
      end
    end
    p @reply
    client.puts("#{@reply}")
  end

  def write_file(client, msg)
    fname = msg[/WRITE:(.*)\n/,1]
    msg = client.gets
    ts = msg[/^TS:(.*)\n/,1]

    if !@@files[fname]
      @reply = "ERROR:This file does not exist\n"
    else
      if (@@files[fname].updateTS(ts))
        p "#{@pm}"
        ts = @@files[fname].get_ts
        @reply = "OK:#{fname}\nTS:#{ts}\nPM:#{@pm}\n"
      else
        @reply = "ERROR:Timeout Error\n"
      end
    end
    client.puts("#{@reply}")

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
s = Server.new(2000)