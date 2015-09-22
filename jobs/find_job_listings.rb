module FindJobListings
	require 'active_support/all'
	require 'json'
	require "indeed-ruby"
	require 'byebug'
	require 'awesome_print'
	require 'nokogiri'
	require 'open-uri'

	# API key is needed for Indeed, but not the others
	INDEED_PUBLISHER_NUMBER = ENV["INDEED_PUBLISHER_NUMBER"]
	
	class Indeed_API
		attr_reader :client # an Indeed::Client
		def initialize
			publisher_number = INDEED_PUBLISHER_NUMBER
			@client = Indeed::Client.new(publisher_number)
		end
		def jobs(options={})
			# takes limit, start, and search_term options
			# plus any params specific to the chosen API (see #defaults)
			if options[:search_term]
				# rename search_term param for specific API
				options[:q] = options.delete(:search_term)
			end
			useful_data(
				client.search(defaults.merge(options))['results']
			)
		end
		def defaults
			{
				q: 'ruby',
				l: 'san francisco',
				limit: 2,
				start: 0,
				userip: '1.2.3.4',
				useragent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/44.0.2403.89 Chrome/44.0.2403.89 Safari/537.36'
			}
		end
		def useful_data(jobs)
			# filter useful info from results
			jobs.map do |job|
				{
					jobtitle: job['jobtitle'],
					description: job['snippet'],
					company: job['company'],
					location: job['formattedLocation'],
					source: job['source'],
					url: job['url']
				}
			end
		end
	end

	class StackOverflow_API
		attr_reader :data, :base_url
		def initialize
			@base_url = "http://careers.stackoverflow.com/jobs/feed"
		end
		def jobs(options={})
			# takes limit, start, and search_term options
			# plus any params specific to the chosen API (see #defaults)
			if options[:search_term]
				# rename search_term param for specific API
				options[:searchTerm] = options.delete(:search_term)
			end
			options = defaults.merge(options)
			url = URI::encode(
				"#{base_url}?#{options.map{ |k,v| "#{k}=#{v}"}.join("&")}"
			)
			open(url) { |results| @data = results.read }
			items = Nokogiri::XML(@data).css("item")
			results = useful_data(items)
			limit = options[:limit].to_i
			offset = options[:start].to_i * limit.to_i if limit
			results[offset...(offset + limit)]
		end
		def defaults
			{
				location: "San Francisco",
				range: 20,
				limit: 2,
				start: 0,
				searchTerm: "ruby"
			}
		end
		def useful_data(items)
			items.map do |item|
				{
					title: item.css("title").text,
					description: item.css("description").text,
					location: item.css("location").text,
					link: item.css("link").text,
				}
			end
		end
	end
end

if __FILE__ == $0
	options = ARGV.reduce({}) do |options, arg|
		key = arg.scan(/(.+)=.+/).flatten.first
		val = arg.gsub("#{key}=", "")
		options[key.to_sym] = val
		options
	end
	interface = "FindJobListings::#{options.delete(:source)}".constantize.new
	jobs = interface.jobs(options)
	ap jobs, indent: 2
	true
end
true