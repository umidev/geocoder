require 'rinda/tuplespace'
require 'open-uri'
require 'aws/s3'
require 'aws/s3/exceptions'
require 'cgi'
require 'base64'
include AWS::S3

HNAME = open('http://169.254.169.254/latest/meta-data/public-hostname').read
PROT = 'druby'
SERVER_PORT = 12131
SERVER_URI = "#{PROT}://#{HNAME}:#{SERVER_PORT}"
puts SERVER_URI

WRKR_PORT = 12140
WRKR_URI = "#{PROT}://#{HNAME}:#{WRKR_PORT}"

secret_access_key = ENV['AMAZON_SECRET_ACCESS_KEY']
access_key_id = ENV['AMAZON_ACCESS_KEY_ID']
GEOCODER_BUCKET = ENV['GEOCODER_BUCKET']
puts 'Geocoder bucket:', GEOCODER_BUCKET
# secret_access_key_esc = CGI::escape(secret_access_key)
# puts secret_access_key_esc
# secret_access_key_64 = Base64.encode64(secret_access_key)
# puts secret_access_key_64
# secret_access_key_20 = secret_access_key.gsub(/ /, '%20')
# puts secret_access_key_20

AWS::S3::Base.establish_connection!(
 :access_key_id => access_key_id,
 :secret_access_key => secret_access_key
)

begin
  buckets = AWS::S3::Service.buckets
  #puts buckets
rescue AWS::S3::ResponseError => error
  puts 'Uh oh. ResponseError', error.response
  puts error
end

puts 'Connection established.'
class GeoS3 < AWS::S3::S3Object
  set_current_bucket_to GEOCODER_BUCKET
end
puts 'Bucket set'
SVR_LOC = ENV['GEOCODER_FLOCK']
