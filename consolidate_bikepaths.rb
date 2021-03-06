require_relative './helpers'

bikepaths = CSV.parse(File.read('./bike-path-data.csv'), headers: true)
bikepaths_by_name = bikepaths.select { |row| row['year'].to_i <= 2012 }.group_by { |row| row['bike_path_name'] }

def find_complete_paths(path_segments)
  longest_segment = path_segments.max_by(&:length)
  path_segments.delete(longest_segment)
  complete_path = longest_segment

  while path_segments.length > 0
    begins_at_my_end, be_min = min_and_value(path_segments) { |seg| distance_between(complete_path.last, seg.first) }
    ends_at_my_begin, eb_min = min_and_value(path_segments) { |seg| distance_between(complete_path.first, seg.last) }
    begins_at_my_begin, bb_min = min_and_value(path_segments) { |seg| distance_between(complete_path.first, seg.first) }
    ends_at_my_end, ee_min = min_and_value(path_segments) { |seg| distance_between(complete_path.last, seg.last) }

    values = [be_min, eb_min, bb_min, ee_min]

    puts "min distance is #{values.min}"
    if values.min > 0.02
      puts "recursing..."
      return [complete_path] + find_complete_paths(path_segments)
    end

    if values.min == be_min
      complete_path = complete_path + path_segments.delete(begins_at_my_end)
    elsif values.min == eb_min
      complete_path = path_segments.delete(ends_at_my_begin) + complete_path
    elsif values.min == ee_min
      complete_path = complete_path + path_segments.delete(ends_at_my_end).reverse
    else
      complete_path = path_segments.delete(begins_at_my_begin).reverse + complete_path
    end
  end

  [complete_path]
end


CSV.open('./joined-bikepaths.csv', 'w', headers: bikepaths.headers, write_headers: true) do |output|

  i = 0
  bikepaths_by_name.each do |name, path_points|
    path_segments = path_points.group_by { |row| row['path_id'] }.values

    complete_paths = find_complete_paths(path_segments)

    complete_paths.each do |complete_path|
      complete_path.each_with_index do |segment, j|
        segment['path_id'] = i
        segment['step'] = j
        output << segment
      end
      i += 1
    end
  end


  #bikepaths_by_name.each_with_index do |(name,path_points), i|
    #path_segments = path_points.group_by { |row| row['path_id'] }.values
    #longest_segment = path_segments.max_by(&:length)
    #path_segments.delete(longest_segment)
    #complete_path = longest_segment

    #puts "trying to combine segments for #{name}"

    #while path_segments.length > 0
      #begins_at_my_end, be_min = min_and_value(path_segments) { |seg| distance_between(complete_path.last, seg.first) }
      #ends_at_my_begin, eb_min = min_and_value(path_segments) { |seg| distance_between(complete_path.first, seg.last) }
      #begins_at_my_begin, bb_min = min_and_value(path_segments) { |seg| distance_between(complete_path.first, seg.first) }
      #ends_at_my_end, ee_min = min_and_value(path_segments) { |seg| distance_between(complete_path.last, seg.last) }

      #values = [be_min, eb_min, bb_min, ee_min]

      #puts "min distance is #{values.min}"
      #binding.pry if values.min > 0.02

      #if values.min == be_min
        #complete_path = complete_path + path_segments.delete(begins_at_my_end)
      #elsif values.min == eb_min
        #complete_path = path_segments.delete(ends_at_my_begin) + complete_path
      #elsif values.min == ee_min
        #complete_path = complete_path + path_segments.delete(ends_at_my_end).reverse
      #else
        #complete_path = path_segments.delete(begins_at_my_begin).reverse + complete_path
      #end
    #end

    #complete_path.each_with_index do |segment, j|
      #segment['path_id'] = i
      #segment['step'] = j
      #output << segment
    #end
  #end
end
