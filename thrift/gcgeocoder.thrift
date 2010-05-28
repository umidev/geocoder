/*
    From geocoder/us example and comments in database.rb

#  [{:pretyp=>"", :street=>"Pennsylvania", :sufdir=>"NW", :zip=>"20502",
#    :lon=>-77.037528, :number=>"1600", :fips_county=>"11001", :predir=>"",
#    :precision=>:range, :city=>"Washington", :lat=>38.898746, :suftyp=>"Ave",
#    :state=>"DC", :prequal=>"", :sufqual=>"", :score=>0.906, :prenum=>""}]

# * The :lat and :lon values of each hash store the range-interpolated
#   address coordinates as latitude and longitude in the WGS84 spheroid.
# * The :precision value may be one of :city, :zip, :street, or :range, in
#   order of increasing precision.
# * The :score value will be a float between 0.0 and 1.0 representing
#   the approximate "goodness" of the candidate match.
# * The other values in the hash will represent various structured
#   components of the address and place name.
*/


namespace rb GeocommonsGeocoderThrift
namespace py geocommons_geocoder_thrift

enum PrecisionType {
    CITY = 1,
    ZIP = 2,
    STREET = 3,
    INTERSECTION = 4,
    RANGE = 5
}

struct GeocodeResult {
    // matched address
    1: map<string,string> address,
    
    // geographic location
    2: double lon,
    3: double lat,

    // result quality
    4: PrecisionType precision,
    5: double score
}

// Results from a single geocode attempt
struct GeocodeResults {
    1: list<GeocodeResult> results
}

service GeocoderService {
    GeocodeResults geocode(1:string address),
    list<GeocodeResults> batch_geocode(1:list<string> addresses)
}

