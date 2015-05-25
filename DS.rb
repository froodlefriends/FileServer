# DIRECTORY SERVER

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

  def add(s_port)
    @servers[s_port] = 1
  end

  # To get list of servers holding replicas. Returns list
  def getList
    c = ''
    @servers.each do |pt, val|
      if val
        @@currServs[pt] = @servers[pt]
        #p val
        c += "#{pt}\n"
      end
    end
    return c
  end

  # To acquire the lock if it is free when first request it
  def lock
    #p @lock
    if @lock<1
      @lock = 1
      t = Time.new
      @ts=t.to_i
      return 1
    else
      return 0
    end
  end

  # If fail on first attempt, sleep and try again using acquire_lock
  def acquire_lock
    if @lock < 1
      return 1
    else
      c_ts = Time.new
      curr_ts = c_ts.to_i
      if (@ts - curr_ts > 10)
        @ts = curr_ts         # Time out lock if another client waiting too long
        return 1
      else
        return 0
      end
    end
  end

  # If the client holding the lock doesn't update regularly enough, the lock is taken off them
  # If they show sign of life, update the lock's time stamp to make sure lock isn't taken off them
  def updateTS(c_ts)

    if (c_ts.to_i == @ts)
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
    p 'unlocking'
    @lock = 0
  end

end


class Pool

  def initialize(port, size)

    # Size thread pool and Queue for storing clients
    @size = size
    @jobs = Queue.new

    @@liveServers = Hash.new
    @@files = Hash.new

    @pm = 0

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

  # Server joining network. First server becomes primary manager,
  # subsequent ones are replica managers so can only read from them
  def join(client, msg)
    s_port = msg[/^JOIN:(.*)\n/,1]
    msg = client.gets
    #p s_port

    if @pm<1
      #p 'about to become pm'
      s_pm = 1
      @pm = s_port
    else
      #p 'not pm'
      s_pm = 0
    end

    t_list = msg[/^LIST:(.*)\n/,1]

    begin
      if !@@files[t_list]
        @@files[t_list] = DirectoryFile.new(t_list)
      end
      @@files[t_list].add(s_port)

      t_list = client.gets.chomp
    end while t_list != ''
    @reply = "ACK: #{s_port}"
    @reply += "\nISPM:#{s_pm}\n"
    client.puts("#{@reply}")

  end

  # When the PM writes to a file it must tell the RMs to write to file too.
  # REP is the call for the list of replica managers that have the file in question
  def rep(client, msg)
    f_name = msg[/^REP:(.*)\n/,1]

    c = @@files[f_name].getList()
    @reply = "OK:#{f_name}\nRMLIST:#{c}\n"
    client.puts("#{@reply}")
  end

  # Open file locks the file until it is closed again
  def open_file(client, msg)
    fname = msg[/^OPEN:(.*)\n/,1]
    @reply = ''
    if !@@files[fname]
      @reply = "ERROR:This file does not exist\n"
    else
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
          sleep(2)
          proc = @@files[fname].acquire_lock
        end
        c = @@files[fname].getList()
      end
      lck = 1
      ts = @@files[fname].get_ts
      @reply = "OK:#{fname}\nTS:#{ts}\nLOCK:#{lck}\nSLIST:#{c}\n"
    end
    client.puts("#{@reply}")

  end

  # File is unlocked in close_file
  def close_file(client, msg)
    fname = msg[/CLOSE:(.*)\n/,1]
    msg = client.gets
    ts = msg[/^TS:(.*)\n/,1]

    if !@@files[fname]
      @reply = "ERROR:This file does not exist\n"
    else
      if (@@files[fname].updateTS(ts)>0)
        @@files[fname].unlock()
        c = @@files[fname].getList()
        @reply = "OK:#{fname}\nSLIST:#{c}\n"
      else
        @reply = "ERROR:Timeout Error\n"
      end
    end

    client.puts("#{@reply}")
  end

  # Find out what servers can read from
  def read_file(client, msg)
    fname = msg[/READ:(.*)\n/,1]
    msg = client.gets
    ts = msg[/^TS:(.*)\n/,1]
    ts = ts.to_i
    if !@@files[fname]
      @reply = "ERROR:This file does not exist\n"
    else
      if (@@files[fname].updateTS(ts))
        c = @@files[fname].getList()
        ts = @@files[fname].get_ts
        @reply = "OK:#{fname}\nTS:#{ts}\nSLIST:#{c}\n"
      else
        @reply = "ERROR:Timeout Error\n"
      end
    end
    client.puts("#{@reply}")
  end

  # Find out who is primary manager so can write to file
  def write_file(client, msg)
    fname = msg[/WRITE:(.*)\n/,1]
    msg = client.gets
    ts = msg[/^TS:(.*)\n/,1]

    if !@@files[fname]
      @reply = "ERROR:This file does not exist\n"
    else
      if (@@files[fname].updateTS(ts))
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