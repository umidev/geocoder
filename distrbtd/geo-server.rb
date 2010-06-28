#!/usr/bin/ruby
require 'rubygems'
require 'geocoder/us'
require 'yaml'

require 'rinda/tuplespace'
require 'aws/s3'
require 'aws/s3/exceptions'
require 'iconv'
require 'geo-drb'
include AWS::S3

#DRb::DRbConnError

# geo-drb until this point
svr_loc = SVR_LOC
unless GeoS3.exists? svr_loc then
begin
  # try to start a server
  GeoS3.store(svr_loc, SERVER_URI, :content_type => 'text/plain')
  puts 'Successfully stored'
  DRb.start_service(SERVER_URI, Rinda::TupleSpace.new)
  DRb.thread.join
rescue AWS::S3::ResponseError => error
  puts error
end
else
  # start up a worker instead
  @db = Geocoder::US::Database.new(ENV['GEOCODER_DB'])

  svr_uri = GeoS3.value svr_loc
  wrkr_port = WRKR_PORT
  wrkr_uri = "#{PROT}://#{HNAME}:#{wrkr_port}"
  begin
    wrkr_uri = "#{PROT}://#{HNAME}:#{wrkr_port}"
    DRb.start_service(wrkr_uri) #SERVER_URI)
    puts "Started worker at #{wrkr_uri}"
  rescue Errno::EADDRINUSE => error
    wrkr_port += 1
    retry if wrkr_port <= 12150
  end

  puts 'Worker started'
  svr_uri = GeoS3.value(svr_loc)
  ts = Rinda::TupleSpaceProxy.new(DRbObject.new(nil, svr_uri))
  puts "Worker joined tuplespace #{ts}"
  puts "Worker connected to tuplespace #{ts}"
  loop do #ts.take([ %r{^[-+/*]$},
    puts 'Worker looping'
    #tup = ts.take(['address', String, String, String, nil])
    tup = ts.take(['addresses', Array])
    puts "Worker took tuple #{tup}"
    addresses = tup[1]
    results = Array.new
    addresses.each { |address|
      #next if address == 'addresses'
      #direction, city, state, zip = tup
      addrstr = address.join(', ')
      addrstr = Iconv.conv('ASCII//TRANSLIT//IGNORE', 'WINDOWS-1252', addrstr)
      puts "Geocoding address: #{addrstr}"
      result = @db.geocode(addrstr.strip)
      YAML::dump(result, $stdout)
      results << result
    }
    ts.write(["results", results])
    $stderr.print 'Worker wrote result\n' if @debug
  end
end
