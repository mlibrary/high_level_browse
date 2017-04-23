require 'lcsort'
require 'logger'
#use dry-inject for this!!!
unless defined? LOGGER
  LOGGER = Logger.new(STDIN)
end

class HighLevelBrowse::CallNumberRangeSet < Array
  def topics_for(str)
    normalized = Lcsort.normalize(str)
    topics = Set.new
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

  attr_accessor :topic_array, :redundant

  def initialize(start=nil, stop=nil, topic_array = [])
    @illegal = false
    @redundant = false
    self.begin = start
    self.end  = stop
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


  def reconstitute(start, stop, start_num, stop_num, letter, topic_array)
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
    cnr = self.new
    cnr.reconstitute(*(h['data']))
    cnr
  end

  # We take advantage of the fact that no HLB ranges cross first-letter
  # boundaries and set it here
  #
  # In both begin= and end=, we also rescue any parsing errors
  # and simply set the @illegal flag so we can use it later on.
  def begin=(x)
    @begin_raw = x
    return if x.nil?
    begin
      @letter = x.upcase.strip[0]
      @begin = Lcsort.normalize(x)
    rescue => e
      @illegal = true
      LOGGER.warn "#{e} doesn't lc-ify"
      # puts "Error: #{e}. Can't work with #{self}" LOG LOG LOG
    end

  end

  # Same as start. Set the illegal flag if we get an error
  def end=(x)
    @end_raw = x
    return if x.nil?
    letter = x.upcase.strip[0]
    $stderr.puts "Crossing letter-lines! #{self}" if @letter and @letter != letter
    begin
      @end = Lcsort.normalize(x)
    rescue
      @illegal = true
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
