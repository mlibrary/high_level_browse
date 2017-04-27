require "high_level_browse/version"
require 'high_level_browse/db'
require 'httpclient'


module HighLevelBrowse

  SOURCE_URL = ENV['HLB_XML_ENDPOINT'] || 'https://www.lib.umich.edu/browse/categories/xml.php'

  # Fetch a new version of the raw file and turn it into a db
  # @return [DB] The loaded database
  def self.fetch
    res = HTTPClient.get(SOURCE_URL, :follow_redirect => false)
    raise "Could not fetch xml from '#{SOURCE_URL}' (status code #{res.status})" unless res.status == 200
    return DB.new_from_xml(res.content)
  end


  # Fetch and save to the specified directory
  # @param [String] dir The directory where the hlb.json.gz file will end up
  # @return [DB] The fetched and saved database
  def self.fetch_and_save(dir:)
    db = self.fetch
    db.save(dir: dir)
    db
  end


  # Load from disk
  # @param [String] dir The directory where the hlb.json.gz file is located
  # @return [DB] The loaded database
  def self.load(dir:)
    DB.load(dir: dir)
  end

end
