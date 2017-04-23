require 'oga'
require 'high_level_browse/call_number_range'
require 'zlib'
require 'json'
require 'high_level_browse/errors'
require 'logger'
#use dry-inject for this!!!
unless defined? LOGGER
  LOGGER = Logger.new
end

class HighLevelBrowse::DB

  FILENAME = 'hlb.json.gz'

  attr_accessor :ranges

  def initialize
    @ranges = {}
    @topics = {}
    @all    = []
    ('A'..'Z').each { |letter| @ranges[letter] = HighLevelBrowse::CallNumberRangeSet.new }
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
    begin
      norm   = raw_callnumber_string.upcase.strip
      letter = norm[0]
      @ranges[letter].topics_for(norm)
    rescue => e # probably malformed or a well-formed dewey, which we don't deal with yet
      []
    end
  end

  alias_method :[], :topics



  # Use Oga to parse out the raw XML and create a set of
  # HLB::CallNumberRange objects, ready for
  # sorting, de-duplication, and saving

  def self.new_from_raw(xml)
    db = self.new
    $stderr.puts "Parsing XML"
    doc = Oga.parse_xml(xml)
    $stderr.puts "Building nodes"
    db.build_nodes(doc)
    $stderr.puts "Pruning"
    db.prune!
    db
  end

  def freeze
    @ranges.freeze
    @topics.freeze
    @all.freeze
    self
  end

  def add_range(r)
    return nil if r.illegal?
    @ranges[r.letter] << r
    @topics[r.topic_array] ||= []
    @topics[r.topic_array] << r
    @all << r
  end

  # Remove any ranges that are subsumed by other ranges. If two ranges
  # have the same topic_array, and one lies entirely within the other,
  # then the inner one may be removed.
  #
  # Ranges must be sorted first via #sort_ranges!

  def prune!
    sort_ranges!
    @topics.values.each do |list|
      list.each_with_index do |inner, i|
        list.each_with_index do |outer, o|
          break if o >= i
          if outer.surrounds(inner)
            inner.redundant = true
          end
        end
      end
      # Delete from this topic list
      list.delete_if { |x| x.redundant }
    end
    # Delete from all
    @all.delete_if { |x| x.redundant }
    # Delete from each set of lettered ranges
    @ranges.values.each do |list|
      list.delete_if { |x| x.redundant }
    end
    nil
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
    db
  end

  private

  # Sort the ranges by start
  def sort_ranges!
    @ranges.values.each do |arr|
      arr.sort! { |a, b| a <=> b }
    end
    @topics.values.each do |arr|
      arr.sort! { |a, b| a <=> b }
    end
  end


end
