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

  FILENAME = 'hlb.json.gz'

  attr_accessor :ranges

  def initialize
    @ranges = nil
    @all    = []
  end


  # Get the topic arrays associated with this callnumber
  # of the form:
  #   [
  #     [toplevel, secondlevel],
  #     [toplevel, secondlevel, thirdlevel],
  #      ...
  #   ]
  # @param [String] raw_callnumber_string
  # @return [Array<Array>] A (possibly empty) array of arrays of topics
  def topics(raw_callnumber_string)
    @ranges.topics_for(raw_callnumber_string)
  end

  alias_method :[], :topics


  # Use Oga to parse out the raw XML and create a set of
  # HLB::CallNumberRange objects, ready for
  # sorting, de-duplication, and saving

  def self.new_from_raw(xml)
    db = self.new
    LOGGER.info "Parsing XML"
    doc = Oga.parse_xml(xml)
    LOGGER.info "Building nodes"
    db.build_nodes(doc)
    LOGGER.info "Treeifying"
    db.treeify!
    db.freeze
    db
  end

  def treeify!
    @ranges = HighLevelBrowse::CallNumberRangeSet.new(@all)
    self
  end

  def freeze
    @ranges.freeze
    @all.freeze
    self
  end

  def add_range(r)
    if r.min.nil? or r.max.nil?
      LOGGER.warn "Bad range #{r}"
    else
      @all << r
    end
    self
  end


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

  private

  # Sort the ranges by start
  def sort_ranges!
    @ranges.values.each do |arr|
      arr.sort!
    end
    @topics.values.each do |arr|
      arr.sort!
    end
  end


end
