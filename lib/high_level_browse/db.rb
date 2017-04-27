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

  # Given a bunch of CallNumberRange objects, create a new
  # database with an efficient structure for querying
  # @param [Array<HighLevelBrowse::CallNumberRange>] array_of_ranges
  def initialize(array_of_ranges)
    @all    = array_of_ranges
    @ranges = self.create_letter_indexed_ranges(@all)
  end

  def create_letter_indexed_ranges(all)
    bins = {}
    ('A'..'Z').each do |letter|
      cnrs         = all.find_all {|x| x.firstletter == letter}
      bins[letter] = HighLevelBrowse::CallNumberRangeSet.new(cnrs)
    end
    bins
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
    firstletter = raw_callnumber_string.strip.upcase[0]
    if defined? @ranges[firstletter]
      @ranges[firstletter].topics_for(raw_callnumber_string)
    else
      []
    end
  end


  alias_method :[], :topics

  # Create a new object from a string with the XML
  # in it.
  # @param [String] xml The contents of the HLB XML dump
  #    (e.g., from 'https://www.lib.umich.edu/browse/categories/xml.php')
  # @return [DB]
  def self.new_from_xml(xml)
    oga_doc_root = Oga.parse_xml(xml)
    simple_array_of_cnrs  = cnrs_within_oga_node(node: oga_doc_root)
    self.new(simple_array_of_cnrs).freeze
  end


  # Save to disk
  # @param [String] dir The directory where the hlb.json.gz file will be saved
  # @return [DB] The loaded database
  def save(dir:)
    Zlib::GzipWriter.open(File.join(dir, FILENAME)) do |out|
      out.puts JSON.fast_generate(@all)
    end
  end


  # Load from disk
  # @param [String] dir The directory where the hlb.json.gz file is located
  # @return [DB] The loaded database
  def self.load(dir:)
    simple_array_of_cnrs = Zlib::GzipReader.open(File.join(dir, FILENAME)) do |infile|
      JSON.load(infile.read).to_a
    end
    db = self.new(simple_array_of_cnrs)
    db.freeze
    db
  end


  # Freeze everything
  # @return [DB] the frozen db
  def freeze
    @ranges.freeze
    @all.freeze
    self
  end

  private

  # Recurse through the parsed XML document, at each stage keeping track of
  #  * where we are (what are the xpath children?)
  #  * what the current topics are ([level1, level2])
  # Get all the call numbers assocaited with the topic represented by the given node,
  # as well as all the children of the given node, and send it back as a big ol' array
  # @param [Oga::Node] node A node of the parsed HLB XML file
  # @param [Array<String>] decendent_xpaths A list of xpaths to the decendents of this node
  # @param [Array<String>] topic_array An array with all levels of the topics associated with this node
  # @return [Array<HighLevelBrowse::CallNumberRange>]
  def self.cnrs_within_oga_node(node:, decendent_xpaths: ['/hlb/subject', 'topic', 'sub-topic'], topic_array: [])
    if decendent_xpaths.empty?
      [] # base case -- we're as low as we're going to go
    else
      current_xpath_component = decendent_xpaths[0]
      new_xpath               = decendent_xpaths[1..-1]
      new_topic = topic_array.dup
      new_topic.push node.get(:name) unless node == node.root_node # skip the root
      cnrs = []
      # For each sub-component, get both the call-number-ranges (cnrs) assocaited
      # with this level, as well as recusively getting from all the children
      node.xpath(current_xpath_component).each do |c|
        cnrs += call_numbers_list_from_leaves(node: c, topic_array: new_topic)
        cnrs += cnrs_within_oga_node(node: c, decendent_xpaths: new_xpath, topic_array: new_topic)
      end
      cnrs
    end
  end




  # Given a second-to-lowest-level node, get its topic and
  # extract call number ranges from its children
  def self.call_numbers_list_from_leaves(node:, topic_array:)
    cnrs = []
    new_topic = topic_array.dup.push node.get(:name)
    node.xpath('call-numbers').each do |cn_node|
      min = cn_node.get(:start)
      max = cn_node.get(:end)

      new_cnr = HighLevelBrowse::CallNumberRange.new(start: min, stop: max, topic_array: new_topic)
      if new_cnr.illegal?
        # do some sort of logging
      else
        cnrs.push new_cnr
      end
    end
    cnrs

  end



end
