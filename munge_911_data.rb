require 'json'
require 'pry'
require 'set'
require 'net/http'
require 'active_support/all'
require 'csv'
require 'cgi'

def reverse_geocode(address)
  JSON.parse(Net::HTTP.get(URI("http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/find?f=json&text=#{CGI.escape(address)}")))['locations'][0]['feature']['geometry'].values_at('y', 'x')
rescue
  puts "error! #{$!}"
  nil
end

dataset911 = JSON.parse(File.read('./boston911Calls.json'))

data911 = dataset911['data']

def address_of(row)
  "#{row[-2]} #{row[-1]}" if row.last.to_s.downcase != 'other' && row[-2].present?
end

localized_data = []

data911.each do |row|
  if address = address_of(row)
    if latlng = reverse_geocode(address)
      localized_data << row+latlng
    end
  end
end

all_headers = dataset911['meta']['view']['columns'].map { |col| col['name'].gsub(/\W/,'').titleize } + ['Latitude', 'Longitude']
desired_headers = all_headers - ['Sid', 'Id', 'Position', 'Created At', 'Updated At', 'Created Meta', 'Updated Meta', 'Meta']

CSV.open('./munged911Data.csv', 'w', headers: desired_headers, write_headers: true) do |csv|
  localized_data.each do |row|
    full_row_hash = Hash[all_headers.zip(row)]
    csv << full_row_hash.values_at(*desired_headers)
  end
end
