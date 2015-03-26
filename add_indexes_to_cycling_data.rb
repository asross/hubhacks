require 'pry'
require 'csv'
require 'json'

input = CSV.parse(File.read('./flattened_cycling_data.csv'), headers: true)

CSV.open('./flattened_cycling_data_with_indexes.csv', 'w', headers: ['Latitude', 'Longitude', 'Activity Type', 'Datetime', 'Route ID', 'Path Index'], write_headers: true) do |output|
  input.group_by { |row| row['Route ID'] }.each do |route_id, rows|
    rows.each_with_index do |row, i|
      row['Path Index'] = i + 1
      output << row
    end
  end
end
