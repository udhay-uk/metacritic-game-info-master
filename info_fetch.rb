require 'rubygems'
require 'fileutils'

require 'logger'
require 'csv'
require 'byebug'

require_relative './master_scrapper'
require_relative './metacritic'

medium = ARGV[0].strip
url = "https://www.metacritic.com/browse/games/release-date/available/#{medium}/date"


cache_loc = "cache/#{medium}"
output_loc = "output"
FileUtils.mkdir_p cache_loc
FileUtils.mkdir_p output_loc
FileUtils.mkdir_p "log/"

logger = Logger.new("log/scrape_#{medium}.log")
logger.level = Logger::INFO

scrapper = MasterScrapper.new(logger, cache_loc)

page = scrapper.fetch("list_0", url, {view: "condensed"})
total_page = Metacritic.last_page(page)

logger.info "Fetching for #{medium}."
logger.info "Total Page Found: #{total_page}."

output_file_path = "#{output_loc}/#{medium}.csv"
output_csv = CSV.open(output_file_path, "w", col_sep: "\t") do |csv|
  total_page.times do |page_no|
    list_page = scrapper.fetch("list_#{page_no}", url, {view: "condensed", page: page_no})
    game_list = Metacritic.list_details(list_page)
    game_list.each do |info|
      game_url = info[0]
      game_name = info[1]
      details_page = scrapper.fetch(game_name, game_url, {view: "condensed", page: page_no})
      game_details = Metacritic.game_details(details_page)
      row = info.concat(game_details).concat([page_no])
      csv << row
    end
  end
end