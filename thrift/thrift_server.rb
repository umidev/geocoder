#!/usr/bin/ruby

require 'rubygems'
require 'geocoder/us'

require 'thrift'
$:.push('gen-rb')

require 'gcgeocoder_types'
require 'geocoder_service'


class GeocodeHandler
    def initialize dbfile
      @db = Geocoder::US::Database.new(dbfile)
    end
  
    def geocode address
        #test_gc = [{:pretyp=>"", :street=>"Pennsylvania", :sufdir=>"NW", :zip=>"20502",
        #  :lon=>-77.037528, :number=>"1600", :fips_county=>"11001", :predir=>"",
        #  :precision=>:range, :city=>"Washington", :lat=>38.898746, :suftyp=>"Ave",
        #  :state=>"DC", :prequal=>"", :sufqual=>"", :score=>0.906, :prenum=>""}]
        results = Array.new
        @db.geocode(address).each do |gc|
#        test_gc.each do |gc|
            result = GeocommonsGeocoderThrift::GeocodeResult.new
            result.lat = gc.delete(:lat)
            result.lon = gc.delete(:lon)
            result.score = gc.delete(:score)
            case gc.delete(:precision)
            when :city
                result.precision = GeocommonsGeocoderThrift::PrecisionType::CITY
            when :zip
                result.precision = GeocommonsGeocoderThrift::PrecisionType::ZIP
            when :street
                result.precision = GeocommonsGeocoderThrift::PrecisionType::STREET
            when :intersection
                result.precision = GeocommonsGeocoderThrift::PrecisionType::INTERSECTION
            when :range
                result.precision = GeocommonsGeocoderThrift::PrecisionType::RANGE
            end
            string_hash = Hash.new
            gc.each do |k,v|
                string_hash[k.to_s] = v
            end
            result.address = string_hash
            results.push result            
        end
        GeocommonsGeocoderThrift::GeocodeResults.new(:results=>results)
    end
    
    def batch_geocode addresses
        addresses.collect{|address| geocode(address)}
    end
end

handler = GeocodeHandler.new ARGV[0]
processor = GeocommonsGeocoderThrift::GeocoderService::Processor.new(handler)
transport = Thrift::ServerSocket.new(80)
transportFactory = Thrift::BufferedTransportFactory.new()
protocolFactory = Thrift::BinaryProtocolFactory.new()

server = Thrift::ThreadPoolServer.new(processor, transport, transportFactory, protocolFactory)

puts "Starting the server..."
server.serve()
puts "done."
