require 'csv'
require 'json'
require 'pry'

CSV.open("bike.csv", "w") do |csv| #open new file for write
  features = JSON.parse(File.open("Existing_Bike_Network.json").read)["features"]
  csv << [ 'bikepath_id','name','length','year','longitude','latitude','path_id', 'step']
  features.each_with_index do |feature, bikepath_id|
    name = feature["properties"]["STREET_NAM"]
    miles = feature["properties"]["LengthMi"]
    year = feature["properties"]["InstallDat"]
    year = 2016 if year == '0'
    geometry = feature["geometry"]
    if geometry && geometry["type"] == "LineString"
      geometry["coordinates"].each_with_index do |coordinate, i|
        longitude = coordinate[0]
        latitude = coordinate[1]
        csv << [bikepath_id, name, miles, year, longitude, latitude, bikepath_id, i+1]
      end
    elsif geometry && geometry["type"] == "MultiLineString"
      geometry["coordinates"].each_with_index do |line, index|
        line.each_with_index do |coordinates, ii|
          longitude = coordinates[0]
          latitude = coordinates[1]
          path_id = bikepath_id.to_s + '-' + index.to_s
          csv << [bikepath_id, name, miles, year, longitude, latitude, path_id, ii+1]
        end
      end
    end
  end
end
