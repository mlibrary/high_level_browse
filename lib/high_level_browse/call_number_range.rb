require 'lcsort'
require 'high_level_browse/range_tree'


# An efficient set of CallNumberRanges from which to get topics
class HighLevelBrowse::CallNumberRangeSet < HighLevelBrowse::RangeTree


  # Returns the array of topic arrays for the given LC string
  # @param [String] raw_lc A raw LC string (eg., 'qa 112.3 .A4 1990')
  # @return [Array<Array<String>>] Arrays of topic labels
  def topics_for(raw_lc)
    normalized = Lcsort.normalize(HighLevelBrowse::CallNumberRange.strip_down_ends(raw_lc))
    self.search(normalized).map(&:topic_array).uniq
  end
end


# A callnumber-range turns callnumbers into integers (or bigints
# for ZZ* callnumbers). It responds much as a Range does (#begin,
# #end, #covers)
class HighLevelBrowse::CallNumberRange
  include Comparable

  attr_reader :begin, :end, :begin_raw, :end_raw, :firstletter

  # Add min/max to make it work with range_tree
  alias_method :min, :begin
  alias_method :max, :end

  attr_accessor :topic_array, :redundant

  SPACE_OR_PUNCT = /[\s\p{Punct}]/

  # @nodoc
  def self.strip_down_ends(str)
    str ||= ''
    str.gsub /\A#{SPACE_OR_PUNCT}*(.*?)#{SPACE_OR_PUNCT}*\Z/, '\1'
  end


  def initialize(start:, stop:, topic_array:)
    @illegal     = false
    @redundant   = false
    self.begin   = self.class.strip_down_ends(start)
    self.end     = self.class.strip_down_ends(stop)
    @topic_array = topic_array
    @firstletter = self.begin[0] unless @illegal
  end


  # Compare based on begin, then end
  # @param [CallNumberRange] o the range to compare to
  def <=>(o)
    b = self.begin <=> o.begin
    if b == 0
      self.end <=> o.end
    else
      b
    end
  end

  def to_s
    "[#{self.begin_raw} - #{self.end_raw}]"
  end

  def reconstitute(start, stop, begin_raw, end_raw, firstletter, topic_array)
    @begin       = start
    @end         = stop
    @begin_raw   = begin_raw
    @end_raw     = end_raw
    @firstletter = firstletter
    @topic_array = topic_array
  end


  # Two ranges are equal if their begin, end, and topic array
  # are all the same
  # @param [CallNumberRange] o the range to compare to
  def ==(other)
    @begin == other.begin and
        @end == other.end and
        @topic_array == other.topic_array
  end


  # @nodoc
  # JSON roundtrip
  def to_json(*a)
    {
        'json_class' => self.class.name,
        'data'       => [@begin, @end, @begin_raw, @end_raw, @firstletter, @topic_array]
    }.to_json(*a)
  end

  # @nodoc
  def self.json_create(h)
    cnr = self.allocate
    cnr.reconstitute(*(h['data']))
    cnr
  end


  # In both begin= and end=, we also rescue any parsing errors
  # and simply set the @illegal flag so we can use it later on.
  def begin=(x)
    @begin_raw     = x
    possible_begin = Lcsort.normalize(x)
    if possible_begin.nil? # didn't normalize
      @illegal = true
      nil
    else
      @begin = possible_begin
    end
  end

  # Same as start. Set the illegal flag if we get an error
  def end=(x)
    @end_raw     = x
    possible_end = Lcsort.normalize(x)
    if possible_end.nil? # didn't normalize
      @illegal = true
      nil
    else
      @end = possible_end + '~' # add a tilde to make it a true endpoint
    end
  end

  def illegal?
    @illegal
  end


  def surrounds(other)
    @begin <= other.begin and @end >= other.end
  end

  def contains(x)
    @begin <= x and @end >= x
  end

  alias_method :cover?, :contains
  alias_method :member?, :contains

end
