require_relative './helpers'

route_summary = CSV.parse(File.read('./route_summary.csv'), headers: true)
routes = CSV.parse(File.read('./geocoded_cycling_data.csv'), headers: true)
collisions = CSV.parse(File.read('./bike_collision_geo.csv'), headers: true)
bikepaths = CSV.parse(File.read('./joined-bikepaths.csv'), headers: true)

headers = ['Data Type', 'Path Id', 'Step', 'Time', 'Street Name', 'Latitude', 'Longitude', 'Step Distance', 'Total Distance', 'Narrative', 'On Bike Lane']

distance_lists = {}

CSV.open('./boston-bike-trips-crashes-and-bike-paths-may2010-dec2012.csv', 'w', headers: headers, write_headers: true) do |output|

  @bikepaths_by_street = Hash.new{|h,street| h[street] = [] }

  def on_bike_lane?(row)
    bikepaths = @bikepaths_by_street[row['Street Name']]
    if bikepaths.length > 0
      path, min_distance = min_and_value(bikepaths) { |seg| distance_between(row, seg) }
      if min_distance < path['Step Distance']
        if Time.parse(row['Time']) > Time.parse(path['Time'])
          return true
        else
          return "Not yet built"
        end
      end
    end
    false
  end

  bikepaths.group_by { |row| row['path_id'] }.each do |path_id, rows|
    segment_data = []

    rows.each_with_index do |row, i|
      next unless row['year'].to_i <= 2012

      if i == 0
        distance = 0
      else
        distance = distance_between(rows[i-1], row)
      end

      street_name = \
        row['name'].to_s.
          sub(' Avenue', ' Ave').
          sub(' Street', ' St').
          sub(' Road', ' Rd').
          sub(/^North/, 'N').
          sub(' Boulevard', ' Blvd').
          sub(' Square', ' Sq').
          sub(' Shared-Use', '').
          sub(' Bridge', ' Brg').
          sub(' Highway', ' Hwy')

      segment = {
        'Data Type'   => 'Bike Path',
        'Path Id'     => row['path_id'],
        'Step'        => row['step'],
        'Time'        => "#{row['year']}-01-01T00:00",
        'Street Name' => street_name,
        'Latitude'    => row['latitude'],
        'Longitude'   => row['longitude'],
        'Step Distance' => distance
      }
      segment_data << segment
      @bikepaths_by_street[street_name] << segment
    end

    calc_total_distance = segment_data.inject(0) { |acc, rd| acc + rd['Step Distance'] }
    #puts "calculated total distance: #{calc_total_distance}"
    #puts "orig total distance: #{rows.map{|row| row['bike_path_length'].to_f}.uniq.sum}"

    segment_data.each do |row_data|
      output << row_data.merge('Total Distance' => calc_total_distance).values_at(*headers)
    end
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
      'Time'        => time.strftime("%FT%R"),
      'Street Name' => row['Address'].to_s[/^(?:\d+\s)?([a-zA-Z0-9 ]+)/, 1],
      'Latitude'    => row["LAT"],
      'Longitude'   => row["LON"],
      'Narrative'   => row["Narrative"]
    }
    row_data['On Bike Lane'] = on_bike_lane?(row_data)

    output << row_data.values_at(*headers)
  end

  city_whitelist = %w(Boston Brookline Brighton Jamaica)

  base_route_id = base_collision_id + collisions.size + 1

  total_miles_by_route_id = Hash[route_summary.map{|rs| [rs['routeid'], rs['distance_m'].to_f*0.000621371] }]

  routes.
    select { |row| Time.parse(row['Datetime']).year <= 2012 }.
    group_by { |row| row['Route ID'] }.
    each_with_index do |(route_id, rows), route_no|

    route_data = []

    total_distance = total_miles_by_route_id[route_id]
    distances = []

    rows.each_with_index do |row, i|
      utc_time = Time.parse(row['Datetime'])
      est_time = Time.at(utc_time.to_f - 4*3600)
      street_name = row['Address'].to_s[/^(?:\d+\s)?([a-zA-Z0-9 ]+), ([a-zA-Z]+)/, 1]
      city_name = row['Address'].to_s[/^(?:\d+\s)?([a-zA-Z0-9 ]+), ([a-zA-Z]+)/, 2]

      if i == rows.length-1
        # this is a bit of a hack, but it should be ok. we can't figure out what
        # the last leg length is so use the total distance to calculate what it ought to be --
        # unless it's way too big. our `distance_between` method throws out a tiny bit of
        # length on each leg.
        distance = [distances.reject{|d| d==0}.mean, total_distance - distances.sum].min
      else
        distance = distance_between(row, rows[i+1])
      end

      route_datum = {
        'Data Type' => 'Runkeeper Route',
        'Path Id' => base_route_id + route_no,
        'Step' => i + 1,
        'Time' => est_time.strftime("%FT%R"),
        'Street Name' => street_name,
        'City Name' => city_name,
        'Latitude' => row['Latitude'],
        'Longitude' => row['Longitude'],
        'Step Distance' => distance
      }
      route_datum['On Bike Lane'] = on_bike_lane?(route_datum)
      route_data << route_datum

      distances << distance
    end

    distance_lists[route_id] = distances

    # remove the beginning and end if they are not in Boston
    unless city_whitelist.include?(route_data.map{|r| r['City Name']}.compact.first)
      while route_data.length > 0 && !city_whitelist.include?(route_data[0]['City Name'])
        route_data.shift
      end
    end

    unless city_whitelist.include?(route_data.map{|r| r['City Name']}.compact.last)
      while route_data.length > 0 && !city_whitelist.include?(route_data[-1]['City Name'])
        route_data.pop
      end
    end

    calc_total_distance = route_data.inject(0) { |acc, rd| acc + rd['Step Distance'] }

    route_data.each do |row_data|
      output << row_data.merge('Total Distance' => calc_total_distance).values_at(*headers)
    end
  end
end
