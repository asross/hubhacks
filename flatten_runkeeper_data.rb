require 'pry'
require 'csv'
require 'json'

input = CSV.parse(File.read('./route_summary.csv'), headers: true)

CSV.open('./flattened_route_data.csv', 'w', headers: ['Latitude', 'Longitude', 'Activity Type', 'Datetime', 'Route ID'], write_headers: true) do |output|
  input.each do |row|
    geodata = JSON.parse(File.read("./geo/#{row['routeid']}.geojson"))
    geodata['features'].first['geometry']['coordinates'].each do |long, lat|
      output << [lat, long, row['activitytype'], row['created_utc'], row['routeid']]
    end
  end
end
