require 'json'
require 'pry'
require 'set'
require 'net/http'
require 'active_support/all'
require 'csv'

incident_dataset = JSON.parse(File.read('./bostonCrimeIncidents.json'))
incident_data = incident_dataset['data']

crime_codes_to_descriptions = {}
nature_codes_to_descriptions = Hash.new { |h, nature_code| h[nature_code] = Hash.new { |h, desc| h[desc] = 0 } }
descriptions_to_nature_codes = Hash.new { |h, description| h[description] = Hash.new { |h, code| h[code] = 0 } }

def ncode(row); row[9].strip.upcase; end
def cdesc(row); row[10].strip; end
def ccode(row); row[11].strip; end

incident_data.each do |row|
  nature_code = ncode(row)
  description = cdesc(row)
  crime_code = ccode(row)

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

data_from_911 = JSON.parse(File.read('./boston911Calls.json'))['data']
all_nature_codes = nature_codes_to_descriptions.keys.sort
nature_code_dictionary_from_911 = Hash[data_from_911.map{|row| [row[11], row[13]] }]

nature_code_dictionary = all_nature_codes.each_with_object({}) do |code, h|
  h[code] = nature_code_dictionary_from_911.fetch(code, 'no definition found')
end

File.open('./natureCodeMeaningsFrom911Data.json', 'w') do |f|
  f.write JSON.pretty_generate(nature_code_dictionary)
end

all_incident_headers = incident_dataset['meta']['view']['columns'].map { |col| col['name'].gsub(/\W/,'').titleize }[0..-2] + ['Latitude', 'Longitude', 'Incident Nature']
desired_incident_headers = all_incident_headers - ['Sid', 'Id', 'Position', 'Created At', 'Updated At', 'Created Meta', 'Updated Meta', 'Meta', 'X', 'Y', 'Ucrpart', 'Year', 'Month', 'Day Week', 'Compnos', 'Xstreetname']

CSV.open('./mungedIncidentData.csv', 'w', headers: desired_incident_headers, write_headers: true) do |csv|
  incident_data.each do |row|
    if human_readable_nature_code = nature_code_dictionary_from_911[ncode(row)]
      _, latitude, longitude, __, ___ = row.last
      full_row = row[0..-2] + [latitude, longitude, human_readable_nature_code]
      full_row_hash = Hash[all_incident_headers.zip(full_row)]
      csv << full_row_hash.values_at(*desired_incident_headers)
    end
  end
end
