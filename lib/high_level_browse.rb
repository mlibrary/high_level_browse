require "high_level_browse/version"
require 'high_level_browse/db'
require 'high_level_browse/errors'
require 'httpclient'
require 'stringio'



module HighLevelBrowse

  SOURCE_URL = ENV['HLB_XML_ENDPOINT'] || 'https://www.lib.umich.edu/browse/categories/xml.php'

  # Fetch a new version of the raw file and turn it into a db
  # @return [HighLevelBrowse::DB] The loaded database
  def self.fetch
    res = HTTPClient.get(SOURCE_URL, :follow_redirect => false)
    raise "Could not fetch xml from '#{SOURCE_URL}' (status code #{res.status})" unless res.status == 200

    return DB.new_from_raw(res.content)
  end


  # Fetch and save to the specified directory
  # @param [String] dir The directory where the hlb.json.gz file will end up
  def self.fetch_and_save(dir:)
    self.fetch.save(dir)
  end

  # Load from disk
  # @param [String] dir The directory where the hlb.json.gz file is located
  # @return [HighLevelBrowse::DB] The loaded database
  def self.load(dir:)
    DB.load(dir)
  end


end
