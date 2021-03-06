require 'pry'
require 'csv'

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

def deg2rad(deg)
  deg.to_f * (Math::PI/180.0)
end

def lat(h)
  h['Latitude'] || h['latitude']
end

def lng(h)
  h['Longitude'] || h['longitude']
end

def distance_between(r1, r2)
  distance_between_latlngs(lat(r1), lng(r1), lat(r2), lng(r2))
end

def distance_between_latlngs(lat1, lon1, lat2, lon2)
  lat1 = deg2rad(lat1); lon1 = deg2rad(lon1)
  lat2 = deg2rad(lat2); lon2 = deg2rad(lon2)
  dlon = lon2 - lon1
  dlat = lat2 - lat1
  a = (Math.sin(dlat/2))**2 + Math.cos(lat1) * Math.cos(lat2) * (Math.sin(dlon/2)) ** 2
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  3_959 * c # earth's radius is 3,959 miles
end

def min_and_value(array, &block)
  min_element = array.min_by(&block)
  min_value = array.map(&block).min
  [min_element, min_value]
end
