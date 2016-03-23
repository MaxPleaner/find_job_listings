module FindJobListings
	require 'active_support/all'
	require 'json'
	require "indeed-ruby"
	require 'byebug'
	require 'awesome_print'
	require 'nokogiri'
	require 'open-uri'
  require 'open_uri_redirections'
	require 'mechanize'

	Agent = Mechanize.new

	class Jobberwocky_API
		attr_reader :jobs_data
		def initialize
                        unless ENV["GITHUB_USERNAME"] && ENV["GITHUB_PASSWORD"]
                          puts "GITHUB_USERNAME and GITHUB_PASSWORD environment variables need to be set."
                          exit
                        end
			sign_in
			jobs_url = "http://progress.appacademy.io/jobberwocky/api/companies"
			jobs_json = Agent.get(jobs_url).content
			@jobs_data = JSON.parse(jobs_json)
		end
		def sign_in
			login_url = "http://progress.appacademy.io/instructors/sign_in"
			login_page = Agent.get(login_url)
			login_button = login_page.link_with(href: "/students/auth/github")
			github_auth_page = login_button.click
			github_login_form = github_auth_page.form(action: "/session")
			github_login_form.login = ENV["GITHUB_USERNAME"]
			github_login_form.password = ENV["GITHUB_PASSWORD"]
			github_callback = Agent.submit(github_login_form)
			github_callback.links[0].click
		end
		def jobs(options={})
			# limit and start options
			options = defaults.merge(options)
			options[:start] = options[:start].to_i
			options[:limit] = options[:limit].to_i
			jobs = @jobs_data.values_at(*(
				options[:start].upto(options[:start] + options[:limit] - 1).to_a
			))
			useful_data(jobs)
		end
		def defaults
			{
				start: 0,
				limit: 100
			}
		end
		def useful_data(jobs)
			jobs.map do |job|
				{
					name: job["name"],
					applied_count: job["app_count"]
				}
			end
		end
	end

	class AngelList_API
		attr_reader :base_url, :response_xml
		def initialize
# -------------------------------------
                        puts "This API source is not functional yet."
                        exit
# -------------------------------------
			@base_url = "https://zapier.com/engine/rss/228093/angellist"
			byebug # unfinished
			true
		end
		def jobs(options={})
			# limit and start options
			open(@base_url){ |response| @response_xml = response }

		end
		def defaults
			{
				limit: 20,
				start: 0
			}
		end
		def useful_data(jobs)
			jobs.map do |job|
				{

				}
			end
		end
	end

	class Indeed_API
		attr_reader :client # an Indeed::Client
		def initialize
      unless ENV["INDEED_PUBLISHER_NUMBER"]
        puts "INDEED_PUBLISHER_NUMBER environment variable needs to be set"
        exit
      end
			publisher_number = ENV["INDEED_PUBLISHER_NUMBER"]
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
				limit: 20,
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
					url: job['url']
				}
			end
		end
	end

	class StackOverflow_API
		attr_reader :response_xml, :base_url
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
			open(url, allow_redirections: :safe) { |results| @response_xml = results.read }
			items = Nokogiri::XML(response_xml).css("item")
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
					location: item.css("location").text.first(250),
					link: item.css("link").text,
				}
			end
		end
	end
end

if __FILE__ == $0
	options = ARGV.reduce({}) do |options, arg|
		key = arg.scan(/(.+)=./).flatten.first
		val = arg.gsub("#{key}=", "")
		options[key.to_sym] = val
		options
	end
       unless options[:source]
         puts "Missing 'source' argument. \nPlease use one of StackOverflow_API, Indeed_API, or Jobberwocky_API. \n For example, `ruby find_job_listings.rb source=Indeed_API limit=10 start=0 search_term=ruby"
         exit 
       end
	interface = "FindJobListings::#{options.delete(:source)}".constantize.new
	jobs = interface.jobs(options)
	ap jobs, indent: 2
	true
end
true
