require 'lcsort'
require 'logger'
#use dry-inject for this!!!
unless defined? LOGGER
  LOGGER = Logger.new(STDERR)
end

class HighLevelBrowse::CallNumberRangeSet < Array
  def topics_for(str)
    normalized = Lcsort.normalize(HighLevelBrowse::CallNumberRange.strip_down_ends(str))
    topics     = Set.new
    self.each do |cnr|
      topics << cnr.topic_array if cnr.contains(normalized)
    end
    topics
  end
end


# A callnumber-range turns callnumbers into integers (or bigints
# for ZZ* callnumbers). It responds much as a Range does (#begin,
# #end, #covers)

class HighLevelBrowse::CallNumberRange
  include Comparable

  attr_reader :begin, :end, :begin_raw, :end_raw, :letter

  # Add min/max to make it work with range_tree
  alias_method :min, :begin
  alias_method :max, :end

  attr_accessor :topic_array, :redundant

  SPACE_OR_PUNCT = /[\s\p{Punct}]/

  def self.strip_down_ends(str)
    str ||= ''
    str.gsub /\A#{SPACE_OR_PUNCT}*(.*?)#{SPACE_OR_PUNCT}*\Z/, '\1'
  end


  def initialize(start=nil, stop=nil, topic_array = [])
    @illegal     = false
    @redundant   = false
    self.begin   = self.class.strip_down_ends(start)
    self.end     = self.class.strip_down_ends(stop)
    @topic_array = topic_array
  end


  # Compare based on begin, then end
  def <=>(o)
    b = self.begin <=> o.begin
    if b == 0
      self.end <=> o.end
    else
      b
    end
  end


  def reconstitute(start, stop, begin_raw, end_raw, letter, topic_array)
    @begin       = start
    @end         = stop
    @begin_raw   = begin_raw
    @end_raw     = end_raw
    @letter      = letter
    @topic_array = topic_array
  end

  def to_s
    "[#{self.begin_raw} - #{self.end_raw}]"
  end

  def ==(other)
    @begin == other.begin and
        @end == other.end and
        @topic_array == other.topic_array
  end


  # JSON roundtrip
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data' => [@begin, @end, @begin_raw, @end_raw, @letter, @topic_array]
    }.to_json(*a)
  end

  def self.json_create(h)
    cnr = self.allocate
    cnr.reconstitute(*(h['data']))
    cnr
  end

  # We take advantage of the fact that no HLB ranges cross first-letter
  # boundaries and set it here
  #
  # In both begin= and end=, we also rescue any parsing errors
  # and simply set the @illegal flag so we can use it later on.
  def begin=(x)
    @begin_raw     = x
    possible_begin = Lcsort.normalize(x)
    if possible_begin.nil?
      LOGGER.warn "Begin value #{x} doesn't lc-ify"
      @illegal = true
      nil
    else
      @letter = possible_begin[0]
      @begin  = possible_begin
    end
  end

  # Same as start. Set the illegal flag if we get an error
  def end=(x)
    @end_raw     = x
    possible_end = Lcsort.normalize(x)
    if possible_end.nil?
      LOGGER.warn "End value #{x} doesn't lc-ify"
      @illegal = true
      nil
    else
      end_letter = possible_end[0]
      @end       = possible_end
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


  alias_method :cover?,  :contains
  alias_method :member?, :contains

  def self.new_from_oga_node(n, topic_array)
    self.new(n.get(:start), n.get(:end), topic_array)
  end



end
