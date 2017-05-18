## update

I'd consider this deprecated in favor of https://github.com/MaxPleaner/job_search_companion

# Find Job Listings

The whole app lives in `find_job_listings.rb` (except for the `Gemfile`).

For Indeed, `nokogiri` is used to parse RSS

For StackOverflow, the JSON parser is used

AngelList is incomplete and nonfunctional.

For Jobberwocky, `mechanize` is used to automate form interaction and JSON is parsed for the job listings

1. `bundle install`
2. `cd jobs`
3. `ruby find_job_listings.rb source=SOURCE`  
  - where SOURCE is `StackOverflow_API`, `Indeed_API`, or `Jobberwocky_API`.
  - For Indeed, `ENV["INDEED_PUBLISHER_NUMBER"]` needs to be set
  - for Jobberwocky (only available to App Academy students), `ENV["GITHUB_USERNAME"]` and `ENV["GITHUB_PASSWORD"]` need to be set
  - other command line options can be specified:
    - `limit=n` returns n jobs
    - `start=n` pages the jobs (beginning at index n)
    - `search_term=ruby` can be used to specify keywords (except when using Jobberwocky).`
