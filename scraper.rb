require 'mechanize'
require "rest_client"
require 'pry-nav'
require 'nokogiri'
require 'csv'

class Scraper 
	attr_reader :rows, :ids, :noko, :counties
	def initialize
		@rows = []
	end

	def get_ocd_ids
		page = RestClient.get("https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-us/census_autogenerated/us_census_places.csv")
		noko = Nokogiri::HTML(page)
		@ids = noko.text.lines.select do |line|
			line =~ /state:ut/
		end.reject do |line|
			line =~ /place:/
		end.map do |line|
			line.gsub(/,.+/, '').gsub(/\n/, '')
		end 
	end 

	def fetch_page
		page = RestClient.get("http://elections.utah.gov/election-resources/county-clerks")
		@noko = Nokogiri::HTML(page)
	end

	def iterate_through_page
		i = 0
		while i < 29 do #from Beaver to Weber (but Sanpete is last)
			county_name = noko.css('td')[i].css('.bold').text
			office = county_name + " County Clerk"
			phone = noko.css('td')[i].text.scan(/\d{3}-\d{3}-\d{4}/).first
	#		website = noko.css('h2')[i].next_element.css('a').text || ""
			id = @ids.find do |i| 
				name = county_name.rstrip.gsub(" County", "").gsub(" ", "_")
				i =~ /county:#{name}/i
			end || ""
			i += 1
			@rows << [county_name + " County", "UT", office, phone, id]	
		end
			@rows.sort!
	end

	def write_into_CSV_file
		CSV.open("spreadsheet.csv", "wb") do |csv|
			@rows.map do |line|
				csv << line
			end
		end
	end

end

a = Scraper.new
a.get_ocd_ids
a.fetch_page
a.iterate_through_page
a.write_into_CSV_file