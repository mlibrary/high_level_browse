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

  # Hard-code filename. If you need more than one, put them
  # in different directories
  FILENAME = 'hlb.json.gz'

  attr_accessor :ranges


  # Given a bunch of CallNumberRange objects, create a new
  # database with an efficient structure for querying
  # @param [Array<HighLevelBrowse::CallNumberRange>] array_of_ranges
  def initialize(array_of_ranges)
    @all = array_of_ranges
    @ranges = HighLevelBrowse::CallNumberRangeSet.new(@all)
    self.freeze
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

  # Create a new object from a string with the XML
  # in it.
  # @param [String] xml The contents of the HLB XML dump
  #    (e.g., from 'https://www.lib.umich.edu/browse/categories/xml.php')
  # @return [DB]
  def self.new_from_xml(xml)
    oga_doc_root = Oga.parse_xml(xml)
    array_of_cnrs = callnumber_ranges_in_oga_node(oga_doc_root)
    require 'pry'; binding.pry

    self.new(array_of_cnrs)
  end


  # Extract the call number ranges from an already-parsed
  # oga document
  #
  # When doing the recursive call, need to make sure we're not
  # continually adding to the topic_array since it'll be passed throughout
  # the recursion and will just end up with lots of dups
  # @param [Oga::Node] node An oga node, parsed from the HLB XML
  # @return [Array<HighLevelBrowse::CallNumberRange>] The call number ranges
  def self.callnumber_ranges_in_oga_node(node, xpath=['/hlb/subject', 'topic', 'sub-topic'], topic_array=[])

    return [] if xpath.empty?

    cnrs = []
    current_xpath_component = xpath.shift
    node.xpath(current_xpath_component).each do |n|
      # ruby doesn't give us a non-mutating #push, so do this nonsense
      ta = topic_array.dup.push n.get(:name)
      n.xpath('call-numbers').each do |cn_node|
        min = cn_node.get(:start)
        max = cn_node.get(:end)
        new_cnr = HighLevelBrowse::CallNumberRange.new(start: min, stop: max, topic_array: ta)
        new_cnrs << new_cnr
      end
      callnumber_ranges_in_oga_node(n, xpath.dup, ta, cnrs + new_cnrs)
    end
  end

  def self.cnrs_within_oga_node(node, xpath=['/hlb/subject', 'topic', 'sub-topic', 'call-numbers'], topic_array=[])
    current_xpath_component = xpath.shift
    if current_xpath_component == 'call-numbers'
      cnrs = []
      n.xpath('call-numbers').each do |cn_node|
        min = cn_node.get(:start)
        max = cn_node.get(:end)
        new_cnr = HighLevelBrowse::CallNumberRange.new(start: min, stop: max, topic_array: topic_array)
        new_cnrs << new_cnr
      end
      cnrs
    else
      ta = topic_array.dup.push node.get(:name)
      node.xpath(current_xpath_component).inject([]) {|c, acc| acc + callnumber_ranges_in_oga_node(c, xpath.dup, ta)}
    end


  end


  def freeze
    @ranges.freeze
    @all.freeze
    self
  end


  #
  # # Build up the list of nodes, adding them via #add_range
  # def build_nodes(node, path=['/hlb/subject', 'topic', 'sub-topic'], topic_array=[])
  #   xp = path.shift
  #   return if xp.nil?
  #   node.xpath(xp).each do |n|
  #     ta = topic_array.dup.push n.get(:name)
  #     n.xpath('call-numbers').each do |cn|
  #       self.add_range HighLevelBrowse::CallNumberRange.new_from_oga_node(cn, ta)
  #     end
  #     build_nodes(n, path.dup, ta)
  #   end
  # end

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
