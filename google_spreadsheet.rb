require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"
require "google/apis/drive_v3"


class GoogleSpreadsheet

  OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
  APPLICATION_NAME = "UploadToSpreadsheet".freeze
  CREDENTIALS_PATH = "google-credentials.json".freeze
  TOKEN_PATH = "token.yaml".freeze
  SCOPE = [
    Google::Apis::SheetsV4::AUTH_SPREADSHEETS,
    Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY
  ]

  def initialize(spreadsheet_name, media)
    @drive_service = Google::Apis::DriveV3::DriveService.new
    @spreadsheet_service = Google::Apis::SheetsV4::SheetsService.new
    @name = spreadsheet_name
    @media = media
  end

  def write_records(records)
    values = records.map { |entry|
      [
        hyperlink(entry[0], entry[1]),
        entry[0],
        entry[2],
        entry[3],
        handle_hyperlinks(entry[4]),
        handle_hyperlinks(entry[5]),
        entry[6].split(",").join("\n"),
        entry[7],
        entry[8]
      ]
    }
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)
    spreadsheet_service.append_spreadsheet_value(spreadsheet_id, "#{media}!A1", value_range, value_input_option: "USER_ENTERED")
  end 

  private
  attr_reader :name, :media, :drive_service, :spreadsheet_service

  def spreadsheet_id
    @spreadsheet_id ||= create_spreadsheet
  end

  def authorize
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "udhayakumarsmilingboy@gmail.com"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  def create_spreadsheet()
    drive_service.client_options.application_name = APPLICATION_NAME
    drive_service.authorization = authorize
    response = drive_service.list_files(
                                fields: "nextPageToken, files(id, name)",
                                page_size: 1,
                                q: "name='#{name}'"
                              )
    file = response.files.first
    spreadsheet_service.client_options.application_name = "spreadsheetuploadproject"
    spreadsheet_service.authorization = authorize
    if file.nil?
      spreadsheet = {
        properties: {
          title: name
        }
      }
      spreadsheet = spreadsheet_service.create_spreadsheet(spreadsheet, fields: 'spreadsheetId')
      return spreadsheet.spreadsheet_id
    end
    return file.id
  end

  def hyperlink(url, name)
    name = name.gsub(/[“”"]+/, "'")
    "=HYPERLINK(\"#{url}\",\"#{name}\")"
  end

  def handle_hyperlinks(ent)
    links = ent.to_s.split(",")
    case links.length
    when 0
      return ""
    when 1
      link = links[0]
      name, url = link.to_s.split('|')
      hyperlink(url, name)
    else
      links.join("\n")
    end
  end
end