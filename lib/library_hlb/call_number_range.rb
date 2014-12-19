require 'lc_callnumber'
require 'library_hlb/bignum'
require 'Set'

class Library::HLB::CallNumberRangeSet < Array
  def topics_for(str)
    big    = Library::HLB::BigNum.from_lc(str)
    topics = Set.new
    self.each do |cnr|
      topics << cnr.topic_array if cnr.contains_int(big)
    end
    topics
  end

end


# A callnumber-range turns callnumbers into integers (or bigints
# for ZZ* callnumbers). It responds much as a Range does (#begin,
# #end, #covers)

class Library::HLB::CallNumberRange

  attr_reader :begin, :end, :begin_num, :end_num, :letter

  attr_accessor :topic_array, :redundant

  def initialize(start=nil, stop=nil, topic_array = [])
    @illegal = false
    @redundant = false
    self.begin = start
    self.end  = stop
    @topic_array = topic_array
  end

  def reconstitute(start, stop, start_num, stop_num, letter, topic_array)
    @begin = start
    @end = stop
    @begin_num = start_num
    @end_num = stop_num
    @letter = letter
    @topic_array = topic_array
  end

  def to_s
    "[#{self.begin} - #{self.end}]"
  end

  def ==(other)
    @begin_num == other.begin_num and
        @end_num == other.end_num and
        @topic_array == other.topic_array
  end


  # JSON roundtrip
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data' => [@begin, @end, @begin_num, @end_num, @letter, @topic_array]
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
    @begin = x
    return if x.nil?
    begin
      @letter = x.upcase.strip[0]
      @begin_num = Library::HLB::BigNum.from_lc(x)
    rescue => e
      @illegal = true
      puts "Error: #{e}. Can't work with #{self}"
    end

  end

  # Same as start. Set the illegal flag if we get an error
  def end=(x)
    @end = x
    return if x.nil?
    letter = x.upcase.strip[0]
    $stderr.puts "Crossing letter-lines! #{self}" if @letter and @letter != letter
    begin
      @end_num = Library::HLB::BigNum.from_lc(x)
    rescue
      @illegal = true
    end
  end

  def illegal?
    @illegal
  end


  def surrounds(other)
    @begin_num <= other.begin_num and @end_num >= other.end_num
  end

  def contains_int(int)
    @begin_num <= int and @end_num >= int
  end

  alias_method :cover?, :contains_int
  alias_method :member?, :member?

  def self.new_from_oga_node(n, topic_array)
    self.new(n.get(:start), n.get(:end), topic_array)
  end



end
