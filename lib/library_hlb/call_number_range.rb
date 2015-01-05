require 'lc_callnumber'
require 'library_hlb/bignum'
require 'library_hlb/interval_tree'
require 'set'

#class Library::HLB::CallNumberRangeSet < Array
#  def topics_for(str)
#    big    = Library::HLB::BigNum.from_lc(str)
#    topics = Set.new
#    comps = 0
#    self.each do |cnr|
#      comps += 1
#      topics << cnr.topic_array if cnr.contains_int(big)
#    end
#    $stderr.puts "Made #{comps} comparisons"
#    topics
#  end
#
#end


class Library::HLB::CallNumberRangeSet < Library::HLB::IntervalTree
  def topics_for(str)
    big    = Library::HLB::BigNum.from_lc(str)
    topics = Set.new
    self.keys_that_cover(big).each do |k|
      topics << k.topic_array
    end
    topics
  end
end


# A callnumber-range turns callnumbers into integers (or bigints
# for ZZ* callnumbers). It responds much as a Range does (#begin,
# #end, #covers)

class Library::HLB::CallNumberRange
  include Comparable

  attr_reader :begin, :end, :begin_str, :end_str

  attr_accessor :topic_array, :redundant

  def initialize(start=nil, stop=nil, topic_array = [])
    @illegal = false
    @redundant = false
    self.begin_str = start
    self.end_str  = stop
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


  def reconstitute(begin_str, end_str, begin_num, end_num, topic_array)
    @begin_str = begin_str
    @end_str = end_str
    @begin = begin_num
    @end = end_num
    @topic_array = topic_array
  end

  def to_s
    "[#{self.begin_str} - #{self.end_str}]"
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
      'data' => [@begin_str, @end_str, @begin, @end, @topic_array]
    }.to_json(*a)
  end

  def self.json_create(h)
    cnr = self.new
    cnr.reconstitute(*(h['data']))
    cnr
  end

  # In both begin= and end=, we rescue any parsing errors
  # and simply set the @illegal flag so we can use it later on.
  def begin_str=(x)
    @begin_str = x
    return if x.nil?
    begin
      @begin = Library::HLB::BigNum.from_lc(x)
    rescue => e
      @illegal = true
      puts "Error: #{e}. Can't work with #{self}"
    end

  end

  # Same as start. Set the illegal flag if we get an error
  def end_str=(x)
    @end_str = x
    return if x.nil?
    begin
      @end = Library::HLB::BigNum.from_lc(x)
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

  def contains_int(int)
    @begin <= int and @end >= int
  end

  alias_method :cover?,  :contains_int
  alias_method :member?, :contains_int

  def self.new_from_oga_node(n, topic_array)
    self.new(n.get(:start), n.get(:end), topic_array)
  end



end
