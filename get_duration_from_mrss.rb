#This script imports a csv with one column contentId. 
#It should be all contentIds for which you want to get durartions.

#For each contentId an Mrss feed is requested which includes all full episode segment durations
#Full episode duration is the sum of all segment durations

#Another csv is exported which has two columns contentID and fullEpisodeDuration


require 'net/http'
require 'Nokogiri'
require 'csv'

#Put the input csv file in same directory as this script

#Edit this variable to be the name of that file
input_file = "cc_durations_input_2017-05-09_2017_05-14.csv"

#Edit this variable to be the name of the output file
output_file = "cc_durations_output_2017-05-09_2017_05-14.csv"

# switch the feed url for other brands
# feed_url = 'http://www.mtv.com/feeds/mrss?uri='
feed_url = 'http://www.cc.com/feeds/mrss?uri='

#This feed class when initialized will make get request for given uuid and store feed response
class MrssFeed
  attr_accessor :response
  def initialize(uuid, feed_url)
    uri = URI(feed_url + uuid)
    self.response = Net::HTTP.get(uri)
  end
  def print_response
    puts @response
  end
end

#create a new feed instance for an mgid and return the sum of all segment durations
def get_duration(mgid, feed_url)

	feed = MrssFeed.new(mgid, feed_url)
  duration = 0.000
  xml_doc = Nokogiri::XML(feed.response)
  xpath = xml_doc.xpath("//media:content")
  xpath.each do |node|
    duration = duration + (node['duration'].to_f * 1000).to_i
  end
  #A status report to make sure things are working
  puts "#{mgid}: #{duration.to_s}"
  return duration
end

#imports csv according to file_name param in same director returns as array
def import_csv(file_name)
  array = Array.new
  index = 1
  CSV.foreach(file_name) do |row|
    if index >= 2
      array[index-2] = row
    end
    index = index + 1
  end
  return array
end

#exports hash as csv
def export_csv(hash, file_name)
  CSV.open(file_name, "wb") {|csv| hash.to_a.each {|elem| csv << elem} }
end
#returns hash for given csv
def csv_to_hash(csv, feed_url)
  hash = {}
  index = 1
  csv.each do |row|
    mgid = row.first
    hash[mgid] = get_duration(mgid, feed_url)
    index = index + 1

  end
  return hash
end

#initialize csv variable as array
csv = import_csv(input_file)
#convert csv to hash
hash = csv_to_hash(csv, feed_url)

export_csv(hash, output_file)
puts "Export is complete, go to sleep"
