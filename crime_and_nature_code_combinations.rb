require 'json'
require 'pry'
require 'set'
require 'net/http'

data = JSON.parse(File.read('./bostonCrimeIncidents.json'))['data']

crime_codes_to_descriptions = {}
nature_codes_to_descriptions = Hash.new { |h, nature_code| h[nature_code] = Hash.new { |h, desc| h[desc] = 0 } }
descriptions_to_nature_codes = Hash.new { |h, description| h[description] = Hash.new { |h, code| h[code] = 0 } }

data.each do |row|
  nature_code = row[9].strip
  description = row[10].strip
  crime_code = row[11].strip

  crime_codes_to_descriptions[crime_code] = description
  nature_codes_to_descriptions[nature_code][description] += 1
  descriptions_to_nature_codes[description][nature_code] += 1
end

def sorted_count_hash(hash)
  hash.keys.sort.each_with_object({}) do |k, result|
    result[k] = Hash[hash[k].sort{|a,b| b[1] <=> a[1]}]
  end
end

File.open('./all_nature_codes.json', 'w') do |f|
  f.write JSON.pretty_generate(nature_codes_to_descriptions.keys.sort)
end

File.open('./all_incident_descriptions.json', 'w') do |f|
  f.write JSON.pretty_generate(descriptions_to_nature_codes.keys.sort)
end

File.open('./possible_descriptions_given_nature_code.json', 'w') do |f|
  f.write JSON.pretty_generate(sorted_count_hash(nature_codes_to_descriptions))
end

File.open('./possible_nature_codes_given_description.json', 'w') do |f|
  f.write JSON.pretty_generate(sorted_count_hash(descriptions_to_nature_codes))
end

File.open('./crime_code_description_mapping.json', 'w') do |f|
  f.write JSON.pretty_generate(crime_codes_to_descriptions)
end
