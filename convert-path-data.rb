require 'csv'
require 'json'
require 'pry'

CSV.open("bike-path-data.csv", "w") do |csv| #open new file for write
  features = %w(1 2 3 4).flat_map{|i| JSON.parse(File.read("./esri#{i}.json"))['features'] }
  csv << [ 'bikepath_id','name','year','longitude','latitude','path_id', 'step']
  features.each_with_index do |feature, bikepath_id|
    attrs = feature['attributes']
    name = attrs["STREET_NAM"]
    year = attrs["InstallDate"]
    year = 2006 if year == '0'
    feature['geometry']['paths'].each_with_index do |path, index|
      path.each_with_index do |coordinates, ii|
        longitude = coordinates[0]
        latitude = coordinates[1]
        path_id = bikepath_id.to_s + '-' + index.to_s
        csv << [bikepath_id, name, year, longitude, latitude, path_id, ii+1]
      end
    end
  end
end
