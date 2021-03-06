require 'pry'
require 'csv'
require 'json'

input = CSV.parse(File.read('./flattened_cycling_data.csv'), headers: true)

headers = ['Latitude', 'Longitude', 'Activity Type', 'Datetime', 'Route ID', 'Path Index', 'Year']

CSV.open('./flattened_cycling_data_with_indexes_and_years.csv', 'w', headers: headers, write_headers: true) do |output|
  input.group_by { |row| row['Route ID'] }.each do |route_id, rows|
    rows.each_with_index do |row, i|
      row['Path Index'] = i + 1
      row['Activity Type'] = 'Cycling'
      time = Time.parse(row['Datetime'])
      row['Year'] = time.year
      output << row.values_at(*headers)
    end
  end
end
