require 'pry'
require 'csv'
require 'set'

routes = CSV.parse(File.read('./geocoded_cycling_data.csv'), headers: true)
collisions = CSV.parse(File.read('./bike_collision_geo.csv'), headers: true)

EARTH_RADIUS = 6_373_000

def deg2rad(deg)
  deg.to_f * (Math::PI/180.0)
end

def distance_between(lat1, lon1, lat2, lon2)
  lat1 = deg2rad(lat1)
  lon1 = deg2rad(lon1)
  lat2 = deg2rad(lat2)
  lon2 = deg2rad(lon2)

  dlon = lon2 - lon1
  dlat = lat2 - lat1
  a = (Math.sin(dlat/2))**2 + Math.cos(lat1) * Math.cos(lat2) * (Math.sin(dlon/2)) ** 2
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  EARTH_RADIUS * c
end

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean
    sum / size.to_f
  end

  def sample_variance
    m = self.mean
    sum = self.inject(0){|accum, i| accum +(i-m)**2 }
    sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end
end

def latlng(route)
  route.to_h.values_at('Latitude', 'Longitude')
end

distances = []

routes.group_by { |route| route['Route ID'] }.each do |route_id, path|
  path.length.times do |i|
    next if i == 0
    distance = distance_between(*latlng(path[i]), *latlng(path[i-1]))
    next if distance == 0
    distances << distance
  end
end

#boston_streets = Set.new

#routes.each do |route|
  #if route['Address'].to_s =~ /^(?:\d+\s)?([a-zA-Z0-9 ]+), Boston/ # comma
    #boston_streets << $1
  #end
#end

#collisions.each do |collision|
  #if collision['Address'].to_s =~ /^(?:\d+\s)?([a-zA-Z0-9 ]+)/ # no comma
    #boston_streets << $1
  #end
#end

collisions_by_street = Hash.new { |h,street| h[street] = 0 }
routes_by_street = Hash.new { |h,street| h[street] = 0 }

trips_and_crashes_by_street = Hash.new { |h, street| h[street] = { trips: 0, crashes: 0 } }

routes.group_by { |route| route['Route ID'] }.each do |route_id, path|
  streets_on_route = Set.new

  path.each do |point|
    if point['Address'].to_s =~ /^(?:\d+\s)?([a-zA-Z0-9 ]+), Boston/
      streets_on_route << $1
    end
  end

  streets_on_route.each do |street|
    trips_and_crashes_by_street[street][:trips] += 1
  end
end

collisions.each do |collision|
  if collision['Address'].to_s =~ /^(?:\d+\s)?([a-zA-Z0-9 ]+)/
    trips_and_crashes_by_street[$1][:crashes] += 1
  end
end

binding.pry