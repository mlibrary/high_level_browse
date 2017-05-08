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


# A callnumber-range keeps track of the original begin/end
# strings as well as the normalized versions, and can be
# serialized to JSON

class HighLevelBrowse::CallNumberRange
  include Comparable

  attr_reader :min, :max, :min_raw, :max_raw, :firstletter


  attr_accessor :topic_array, :redundant

  SPACE_OR_PUNCT = /[\s\p{Punct}]/

  # @nodoc
  def self.strip_down_ends(str)
    str ||= ''
    str.gsub /\A#{SPACE_OR_PUNCT}*(.*?)#{SPACE_OR_PUNCT}*\Z/, '\1'
  end


  def initialize(min:, max:, topic_array:)
    @illegal     = false
    @redundant   = false
    self.min     = self.class.strip_down_ends(min)
    self.max     = self.class.strip_down_ends(max)
    @topic_array = topic_array
    @firstletter = self.min[0] unless @illegal
  end


  # Compare based on @min, then end
  # @param [CallNumberRange] o the range to compare to
  def <=>(o)
    [self.min, self.max] <=> [o.min, o.max]
  end

  def to_s
    "[#{self.min_raw} - #{self.max_raw}]"
  end

  def reconstitute(min, max, min_raw, max_raw, firstletter, topic_array)
    @min         = min
    @max         = max
    @min_raw     = min_raw
    @max_raw     = max_raw
    @firstletter = firstletter
    @topic_array = topic_array
  end


  # Two ranges are equal if their @min, @max, and topic array
  # are all the same
  # @param [CallNumberRange] o the range to compare to
  def ==(other)
    @min == other.min and
        @max == other.max and
        @topic_array == other.topic_array
  end


  # @nodoc
  # JSON roundtrip
  def to_json(*a)
    {
        'json_class' => self.class.name,
        'data'       => [@min, @max, @min_raw, @max_raw, @firstletter, @topic_array]
    }.to_json(*a)
  end

  # @nodoc
  def self.json_create(h)
    cnr = self.allocate
    cnr.reconstitute(*(h['data']))
    cnr
  end


  # In both @min= and end=, we also rescue any parsing errors
  # and simply set the @illegal flag so we can use it later on.
  def min=(x)
    @min_raw     = x
    possible_min = Lcsort.normalize(x)
    if possible_min.nil? # didn't normalize
      @illegal = true
      nil
    else
      @min = possible_min
    end
  end

  # Same as start. Set the illegal flag if we get an error
  def max=(x)
    @max_raw     = x
    possible_max = Lcsort.normalize(x)
    if possible_max.nil? # didn't normalize
      @illegal = true
      nil
    else
      @max = possible_max + '~' # add a tilde to make it a true endpoint
    end
  end

  def illegal?
    @illegal
  end


  def surrounds(other)
    @min <= other.min and @max >= other.max
  end

  def contains(x)
    @min <= x and @max >= x
  end

  alias_method :cover?, :contains
  alias_method :member?, :contains

end
