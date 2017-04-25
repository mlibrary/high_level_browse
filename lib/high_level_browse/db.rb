require 'oga'
require 'high_level_browse/call_number_range'
require 'zlib'
require 'json'
require 'high_level_browse/errors'
require 'logger'
#use dry-inject for this!!!
unless defined? LOGGER
  LOGGER = Logger.new(STDERR)
end


class HighLevelBrowse::DB

  # Hardcode the name of the file, because it makes life easier.
  # Multiple files can be put in different directories
  # if need be
  FILENAME = 'hlb.json.gz'

  def initialize
    @ranges = nil # will be the tree structure
    @all    = []
  end


  # Get the topic arrays associated with this callnumber
  # or set of callnumbers of the form:
  #   [
  #     [toplevel, secondlevel],
  #     [toplevel, secondlevel, thirdlevel],
  #      ...
  #   ]
  # @param [String, Array<String>] raw_callnumber_string(s)
  # @return [Array<Array<String>>] A (possibly empty) array of arrays of topics
  def topics(*raw_callnumber_strings)
    raw_callnumber_strings.map{|cn| @ranges.topics_for(cn)}.flatten(1).uniq
  end

  alias_method :[], :topics


  # Use Oga to parse out the raw XML and create a set of
  # HLB::CallNumberRange objects, ready for
  # sorting, de-duplication, turning into a set,
  # and/or saving
  #
  # This is all side effects, so be warned
  # @param [String] xml Valid HLB xml
  # @return [HighLevelBrowse::DB] the DB, ready for querying
  def self.new_from_raw(xml)
    self.new.replace_with_xml(xml)
  end

  # Throw away whatever (if anything) is in this
  # object and replace fully with the XML passed
  # This is all side effects, so be warned
  # @param [String] xml Valid HLB xml
  # @return [HighLevelBrowse::DB] the DB, ready for querying
  def replace_with_xml(xml)
    @all = []
    doc = Oga.parse_xml(xml)
    build_nodes(doc)
    treeify!
    freeze
    self
  end


  # Save to disk
  # @param [String] dir The directory where the hlb.json.gz file will be saved
  # @return [HighLevelBrowse::DB] The loaded database
  def save(dir:)
    Zlib::GzipWriter.open(File.join(dir, FILENAME)) do |out|
      out.puts JSON.fast_generate(@all)
    end
  end

  # Load from disk
  # @param [String] dir The directory where the hlb.json.gz file is located
  def self.load(dir:)
    db = self.new
    Zlib::GzipReader.open(File.join(dir, FILENAME)) do |infile|
      JSON.load(infile.read).each do |r|
        db.add_range(r)
      end
    end
    db.treeify!
    db
  end

  # Take the ranges in @all and turn them into an efficient
  # data structure in @ranges
  # @return [self]
  def treeify!
    @ranges = HighLevelBrowse::CallNumberRangeSet.new(@all)
    self
  end


  def freeze
    @ranges.freeze
    @all.freeze
    self
  end

  # Add a call number range, prior to treeification
  # @param [HighLevelBrowse::CallNumberRange] r
  # @return [self]
  def add_range(r)
    if r.min.nil? or r.max.nil?
      LOGGER.warn "Bad range #{r}"
    else
      @all << r
    end
    self
  end

  private

  # Build up the list of nodes, adding them via #add_range
  def build_nodes(node, path=['/hlb/subject', 'topic', 'sub-topic'], topic_array=[])
    xp = path.shift
    return if xp.nil?
    node.xpath(xp).each do |n|
      ta = topic_array.dup.push n.get(:name)
      n.xpath('call-numbers').each do |cn|
        self.add_range HighLevelBrowse::CallNumberRange.new_from_oga_node(cn, ta)
      end
      build_nodes(n, path.dup, ta)
    end
  end


end
