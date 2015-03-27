require 'pry'
require 'csv'

routes = CSV.parse(File.read('./geocoded_cycling_data.csv'), headers: true)
collisions = CSV.parse(File.read('./bike_collision_geo.csv'), headers: true)
bikepaths = CSV.parse(File.read('./bike-path-data.csv'), headers: true)

headers = ['Data Type', 'Path Id', 'Step', 'Year', 'Month', 'Hour', 'Street Name', 'Latitude', 'Longitude']

CSV.open('./boston-bike-trips-crashes-and-bike-paths-may2010-dec2012.csv', 'w', headers: headers, write_headers: true) do |output|

  bikepaths.each do |row|
    next unless row['year'].to_i <= 2012

    street_name = \
      row['bike_path_name'].
        sub(' Avenue', ' Ave').
        sub(' Street', ' St').
        sub(' Road', ' Rd').
        sub(/^North/, 'N').
        sub(' Boulevard', ' Blvd').
        sub(' Square', ' Sq').
        sub(' Shared-Use', '').
        sub(' Bridge', ' Brg').
        sub(' Highway', ' Hwy')

    row_data = {
      'Data Type'   => 'Bike Path',
      'Path Id'     => row['path_id'],
      'Step'        => row['step'],
      'Year'        => row['year'],
      'Street Name' => street_name,
      'Latitude'    => row['latitude'],
      'Longitude'   => row['longitude']
    }
    output << row_data.values_at(*headers)
  end

  base_collision_id = bikepaths.max_by {|p| p['path_id'].to_i }['path_id'].to_i + 1

  collisions.each_with_index do |row, i|
    next unless row['DATE'].to_s.length > 0
    m, d, y = row['DATE'].split('/')
    time_string = "#{y}-#{m.rjust(2, '0')}-#{d.rjust(2, '0')} #{row['TIME']}"
    time = Time.parse(time_string)
    next unless time >= Time.parse('2010-05-01')

    row_data = {
      'Data Type'   => 'Collision',
      'Path Id'     => base_collision_id + i,
      'Step'        => '1',
      'Year'        => time.year,
      'Month'       => time.month,
      'Hour'        => time.hour,
      'Street Name' => row['Address'].to_s[/^(?:\d+\s)?([a-zA-Z0-9 ]+)/, 1],
      'Latitude'    => row["LAT"],
      'Longitude'   => row["LON"]
    }
    output << row_data.values_at(*headers)
  end

  base_route_id = base_collision_id + collisions.size + 1

  routes.select { |row| Time.parse(row['Datetime']).year <= 2012 }.group_by { |row| row['Route ID'] }.each_with_index do |(route_id, rows), route_no|
    route_data = []

    rows.each_with_index do |row, i|
      utc_time = Time.parse(row['Datetime'])
      est_time = Time.at(utc_time.to_f - 4*3600)
      street_name = row['Address'].to_s[/^(?:\d+\s)?([a-zA-Z0-9 ]+), Boston/, 1]

      route_data << {
        'Data Type' => 'Runkeeper Route',
        'Path Id' => base_route_id + route_no,
        'Step' => i + 1,
        'Year' => est_time.year,
        'Month' => est_time.month,
        'Hour'  => est_time.hour,
        'Street Name' => street_name,
        'Latitude' => row['Latitude'],
        'Longitude' => row['Longitude']
      }
    end

    # skip unless at least some of the route is inside Boston
    next unless route_data.any? { |row_data| row_data['Street Name'].to_s.length > 0 }

    in_boston_yet = false
    route_data.each do |row_data|
      in_boston_yet ||= row_data['Street Name']
      output << row_data.values_at(*headers) if in_boston_yet
    end
  end
end
