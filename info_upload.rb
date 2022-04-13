require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"

require "csv"
require "byebug"

require_relative "./google_spreadsheet"

input_loc = "output"

media = "ios"

input_file_path = "#{input_loc}/#{media}.csv"

buffered_rows = []
buffer_limit = 1000

spreadsheet = GoogleSpreadsheet.new("MetacriticVideoGameUniverse", media)
counter = 0
CSV.foreach(input_file_path, col_sep: "\t", liberal_parsing: true) do |row|
  buffered_rows << row
  if(buffered_rows.length > buffer_limit)
    spreadsheet.write_records(buffered_rows)
    buffered_rows.clear
  end
  counter += 1
end
spreadsheet.write_records(buffered_rows)