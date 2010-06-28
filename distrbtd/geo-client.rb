#!/usr/bin/ruby
require 'rubygems'
require 'geocoder/us'
require 'yaml'

require 'rinda/rinda'
require 'aws/s3'
require 'aws/s3/exceptions'
require 'geo-drb'
include AWS::S3
#---
# sleep 0.1
# pid2 = fork { exec "/usr/local/rubybook/bin/ruby code/rinda/simple_server.rb" }
# sleep 0.1

CLIENT_CHUNK_SIZE = Integer(ENV['CLIENT_CHUNK_SIZE'])
svr_uri = GeoS3.value ENV['GEOCODER_FLOCK']


#MY_URI = "druby://127.0.0.1:12131"
clnt_port = WRKR_PORT
begin
  clnt_uri = "#{PROT}://#{HNAME}:#{clnt_port}"
  DRb.start_service(clnt_uri) #SERVER_URI)
  puts "Started client at #{clnt_uri}"
rescue Errno::EADDRINUSE => error
  clnt_port += 1
  retry if clnt_port <= 12150
end

ts = Rinda::TupleSpaceProxy.new(DRbObject.new(nil, svr_uri))
puts "Client connected to tuplespace: #{ts}"

#queries = [['address', '690 Fifth St', 'San Francisco', 'CA', nil], ['address', '6609 Shattuck Ave', 'Oakland', 'CA', 94609]]
# queries = [['addresses', [['690 Fifth St', 'San Francisco', 'CA'], ['6609 Shattuck Ave', 'Oakland', 'CA']]],
#            ['addresses', [['690 Fifth St', 'San Francisco', 'CA'], ['6609 Shattuck Ave', 'Oakland', 'CA']]],
#            ['addresses', [['690 Fifth St', 'San Francisco', 'CA'], ['6608 Shattuck Ave', 'Oakland', 'CA'], ['6688 Whitney St, Oakland, CA'], ['6630 Shattuck Ave, Oakland, CA'], ['5957 Shattuck Ave, Oakland, CA'], ['5921 Shattuck Ave, Oakland, CA'], ['4734 Shattuck Ave., Oakland, CA'], ['4734 Shattuck Ave., Oakland, CA'], ['5225 Shattuck Avenue, Oakland, CA'] ]]]
#[[ "+", 1, 2 ],  [ "*", 3, 4 ],  [ "/", 8, 2 ]]

space_size = 0
mute = Mutex.new

reader = Thread.new(ts) { |tusp|
  loop do
    results = tusp.take(["results", Array])
    mute.synchronize do
      space_size -= results.length
    end
    results.each { |addresses|
      addresses.each { |address|
        p address
      }
    }
  end
}

query = lambda { |addresses|
  q = ['addresses', addresses]
  print "Client writing query "  # {q}"
  p q
  ts.write(q)
  print "Client wrote query " # {q}"
  p q
  #ans = ts.take(["results", Array])
  #p ans # "#{q[1]} #{q[0]} #{q[2]} = #{ans[1]}"
}

lamb = lambda {
  addresses = Array.new
  ARGF.each_with_index do |line, idx|
    line.chomp!
    addresses << [line]
    next if (idx % CLIENT_CHUNK_SIZE) != 0
    sz = 0
    # Throttle loading of the tuplespace when
    # it gets over a certain size. Should change
    # this to use a conditional variable or callback.
    loop do
      mute.synchronize do
        # register callback
        sz = space_size
      end
      if sz > 2500 then
        sleep 0.1
      else
        break
      end
    end
    query.call(addresses)
    mute.synchronize do
      space_size += addresses.length
    end
    addresses = Array.new
  end
  query.call(addresses) unless addresses.empty?
}
lamb.call

# Process::kill("TERM", pid2)
# Process::kill(9, pid1)
# Process.waitall

reader.join()
