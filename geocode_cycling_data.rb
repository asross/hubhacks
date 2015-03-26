require 'pry'
require 'csv'
require 'json'
require 'net/http'

def reverse_geocode(lat, lng)
  uri = URI("http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/reverseGeocode?f=json&location=#{lng},#{lat}")
  JSON.parse(Net::HTTP.get(uri))['address']['Match_addr']
rescue
  nil
end

input = CSV.parse(File.read('./route_summary.csv'), headers: true)

CSV.open('./geocoded_cycling_data.csv', 'w', headers: ['Latitude', 'Longitude', 'Activity Type', 'Datetime', 'Route ID', 'Address'], write_headers: true) do |output|
  input.each do |row|
    next unless row['activitytype'] == 'Cycling'

    geodata = JSON.parse(File.read("./geo/#{row['routeid']}.geojson"))
    geodata['features'].first['geometry']['coordinates'].each do |long, lat|
      address = reverse_geocode(lat, long)
      output << [lat, long, row['activitytype'], row['created_utc'], row['routeid'], address]
    end
  end
end
