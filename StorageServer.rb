require 'socket'
require 'thread'
require 'fileutils'


class StorageServer

  def initialize(name)
    @cr_members = Hash.new
    @name = name
  end

  def add(nickname, client)
    if !@cr_members[nickname]
      @cr_members[nickname] = client

      @cr_members.each do |nn, client|
        if client and nn != nickname
          client.puts "#{nickname} has joined #{@name} chatroom"
        end
      end

    end
  end

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

  def leave(nickname)
    @cr_members[nickname] = nil

    @cr_members.each do |nn, client|
      if client and nn != nickname
        client.puts "#{nickname} has left #{@name} chatroom"
      end
    end

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

end

class Pool


  def initialize(port, size)

    # Size thread pool and Queue for storing clients
    @folder = 'abc'
    @size = size
    @jobs = Queue.new

    @@clientNum = 0
    @@roomNum = 0
    @@rooms = Hash.new
    @@c_rooms = Hash.new
    @@members = Hash.new
    @@memByID = Hash.new

    if !File.directory?("#{@folder}")
      Dir.mkdir "#{@folder}"
    end
    #Dir.chdir("\#{@folder}")

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
        connected(client)
      when /JOIN_CHATROOM:.*\n/
        join_cr(client, message)
        connected(client)
      when /OPEN:.*\n/
        open_file(client, message)
        connected(client)
      when /CLOSE:.*\n/
        close_file(client, message)
        connected(client)
      when /READ:.*\n/
        read_file(client, message)
        connected(client)
      when /WRITE:.*\n/
        write_file(client, message)
        connected(client)
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
    ex_path = File.expand_path(path)
    puts ex_path
    #File.open("#{Dir.home}/#{path}")
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
=begin
    begin
      msg = client.gets.chomp
      w_msg += "\n#{msg}"
    end while msg != ''
=end

    #puts w_msg
    file = File.open(path, 'wb')
    file.print(w_msg)
    file.close()
    p 'done'
    @reply = "OK: #{fname}\n"

    client.puts("#{@reply}")

    #connected(client)
  end


  def join_cr(client, msg)
    @room = msg[/JOIN_CHATROOM:(.*)\n/,1]
    @clientIP = client.gets
    @clientPort = client.gets
    msg = client.gets
    @nickname = msg[/CLIENT_NAME:(.*)\n/,1]

    if !@@rooms[@room]
      @roomID = @@roomNum += 1
      @@c_rooms[@roomID] = ChatRoom.new(@room)
      @@rooms[@room] = @roomID
    end

    if !@@members[@nickname]
      @clientID = @@clientNum +=1
      @@members[@nickname] = @clientID
      @@memByID[@clientID] = @nickname
    end

    @@c_rooms[@@rooms[@room]].add(@nickname, client)

    @ipAddr = client.peeraddr[3].to_s

    @reply = "JOINED_CHATROOM: #{@room}\n"
    @reply += "SERVER_IP: lg12l15.scss.tcd.ie\n" #{@ipAddr}
    @reply += "Port: #{@port}\n"
    @reply += "ROOM_REF: #{@@rooms[@room]}\n"
    @reply += "JOIN_ID: #{@@members[@nickname]}\n"

    client.puts("#{@reply}")

    #connected(client)
  end

  def connected(client)
    loop{
      message = client.gets
      puts message

      if message[/DISCONNECT:.*\n/]
      disconnect(client, message)
        break
      end

      case message
        when /HELO .*\n/
          helo(client, message)
        when /JOIN_CHATROOM:.*\n/
          join_cr(client, message)
        when /CHAT:.*\n/
          chat(client, message)
        when /LEAVE_CHATROOM:.*\n/
          leave_cr(client, message)
        when /KILL_SERVICE.*\n/
          kill_server
        else
          puts 'unknown'
          unknown(client, message)
      end
    }
  end

  def chat(client, msg)
    @c_room = msg[/CHAT:(.*)\n/,1].to_i
    msg = client.gets
    puts msg
    @clientID = msg[/JOIN_ID:(.*)\n/,1]
    msg = client.gets
    puts msg
    @nickname = msg[/CLIENT_NAME:(.*)\n/,1]

    if !@@c_rooms[@c_room]
      client.puts('ERROR_CODE: 101\nERROR_DESCRIPTION: No such chatroom exists')
      client.close
    end

    @checker = @@c_rooms[@c_room].check_members(@nickname)


    if @checker == 0
      client.puts('ERROR_CODE: 102\nERROR_DESCRIPTION: You have not joined this chatroom')
      client.close
    else
      msg = client.gets
      @chat_msg = msg[/MESSAGE:(.*)\n/,1]

      begin
        msg = client.gets.chomp
        @chat_msg += "\n#{msg}"
      end while msg != ''

      @@c_rooms[@c_room].broadcast(@c_room, @nickname, @chat_msg)
     end

  end

  def leave_cr(client, msg)

    @c_room = msg[/LEAVE_CHATROOM:(.*)\n/,1].to_i
    puts @c_room
    msg = client.gets
    @clientID = msg[/JOIN_ID:(.*)\n/,1]
    puts @clientID
    msg = client.gets
    @nickname = msg[/CLIENT_NAME:(.*)\n/,1]
    puts@nickname

    @@c_rooms[@c_room].leave(@nickname)

    @reply = "LEFT_CHATROOM:#{@c_room}\n"
    @reply += "JOIN_ID: #{@clientID}"

    client.puts("#{@reply}")
  end

  def disconnect(client, msg)
    @clientIP = msg
    @clientPort = client.gets

    msg = client.gets
    @nickname = msg[/CLIENT_NAME:(.*)\n/,1]
    @checker = 0
    @@c_rooms.each_value do |cr|
      if cr
        @checker = cr.check_members(@nickname)
        if @checker
          cr.leave(@nickname)
        end

      end
    end
    client.puts('Goodbye '+"#{@nickname}")
    client.close
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