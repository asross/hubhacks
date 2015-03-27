require 'pry'
require 'csv'

routes = CSV.parse(File.read('./flattened_cycling_data.csv'), headers: true)
collisions = CSV.parse(File.read('./bike_collision_geo.csv'), headers: true)
bikepaths = CSV.parse(File.read('./bike-path-data.csv'), headers: true)

headers = ['Data Type', 'Path Id', 'Step', 'Year', 'Month', 'Street Name', 'Latitude', 'Longitude']

CSV.open('./combined-path-route-and-collision-data.csv', 'w', headers: headers, write_headers: true) do |output|

  bikepaths.each do |row|
    next if row['year'] == '2016' || row['year'] == '0' # skip the future ones

    row_data = {
      'Data Type'   => 'Bike Path',
      'Path Id'     => row['path_id'],
      'Step'        => row['step'],
      'Year'        => row['year'],
      'Month'       => '1',
      'Street Name' => row['bike_path_name'],
      'Latitude'    => row['latitude'],
      'Longitude'   => row['longitude']
    }
    output << row_data.values_at(*headers)
  end

  base_collision_id = bikepaths.max_by {|p| p['path_id'].to_i }['path_id'].to_i + 1

  collisions.each_with_index do |row, i|
    row_data = {
      'Data Type'   => 'Collision',
      'Path Id'     => base_collision_id + i,
      'Step'        => '1',
      'Year'        => row['YEAR'],
      'Month'       => row['DATE'].to_s.split('/')[1],
      'Street Name' => "#{row['Address']}, #{row['PlanningDi']}",
      'Latitude'    => row["LAT"],
      'Longitude'   => row["LON"]
    }
    output << row_data.values_at(*headers)
  end

  base_route_id = base_collision_id + collisions.size + 1

  routes.group_by { |row| row['Route ID'] }.each_with_index do |(route_id, rows), route_no|
    rows.each_with_index do |row, i|
      time = Time.parse(row['Datetime'])
      row_data = {
        'Data Type' => 'Runkeeper Route',
        'Path Id' => base_route_id + route_no,
        'Step' => i + 1,
        'Year' => time.year,
        'Month' => time.month,
        'Street Name' => nil,
        'Latitude' => row['Latitude'],
        'Longitude' => row['Longitude']
      }

      output << row_data.values_at(*headers)
    end
  end
end
