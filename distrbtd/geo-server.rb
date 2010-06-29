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
  $stderr.print "#{error}"
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
    $stderr.print "Started worker at #{wrkr_uri}\n" if @debug
  rescue Errno::EADDRINUSE => error
    wrkr_port += 1
    retry if wrkr_port <= 12150
  end

  $stderr.print 'Worker started\n' if @debug
  svr_uri = GeoS3.value(svr_loc)
  ts = Rinda::TupleSpaceProxy.new(DRbObject.new(nil, svr_uri))
  $stderr.print "Worker joined tuplespace #{ts}\n" if @debug
  $stderr.print "Worker connected to tuplespace #{ts}\n" if @debug
  loop do #ts.take([ %r{^[-+/*]$},
    $stderr.print 'Worker looping\n' if @debug 
    #tup = ts.take(['address', String, String, String, nil])
    tup = ts.take(['addresses', Array])
    $stderr.print "Worker took tuple #{tup}\n" if @debug
    addresses = tup[1]
    results = Array.new
    addresses.each { |address|
      #next if address == 'addresses'
      #direction, city, state, zip = tup
      addrstr = address.join(', ')
      addrstr = Iconv.conv('ASCII//TRANSLIT//IGNORE', 'WINDOWS-1252', addrstr)
      $stderr.print "Geocoding address: #{addrstr}\n" if @debug
      result = @db.geocode(addrstr.strip)
      YAML::dump(result, $stdout)
      results << result
    }
    ts.write(["results", results])
    $stderr.print 'Worker wrote result\n' if @debug
  end
end
