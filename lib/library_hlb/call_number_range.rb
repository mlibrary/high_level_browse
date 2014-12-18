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

class Library::HLB::CallNumberRange

  attr_reader :start, :stop, :start_num, :stop_num, :letter

  attr_accessor :topic_array, :redundant

  def initialize(start=nil, stop=nil, topic_array = [])
    @illegal = false
    @redundant = false
    self.start = start
    self.stop  = stop
    @topic_array = topic_array
  end

  def reconstitute(start, stop, start_num, stop_num, letter, topic_array)
    @start = start
    @stop = stop
    @start_num = start_num
    @stop_num = stop_num
    @letter = letter
    @topic_array = topic_array
  end

  def to_s
    "[#{start} - #{stop}]"
  end

  def ==(other)
    @start_num == other.start_num and
        @stop_num == other.stop_num and
        @topic_array == other.topic_array
  end


  # JSON roundtrip
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data' => [@start, @stop, @start_num, @stop_num, @letter, @topic_array]
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
  # In both start= and stop=, we also rescue any parsing errors
  # and simply set the @illegal flag so we can use it later on.
  def start=(x)
    @start = x
    return if x.nil?
    begin
      @letter = x.upcase.strip[0]
      @start_num = Library::HLB::BigNum.from_lc(x)
    rescue => e
      @illegal = true
      puts "Error: #{e}. Can't work with #{self}"
    end

  end

  # Same as start. Set the illegal flag if we get an error
  def stop=(x)
    @stop = x
    return if x.nil?
    letter = x.upcase.strip[0]
    $stderr.puts "Crossing letter-lines! #{self}" if @letter and @letter != letter
    begin
      @stop_num = Library::HLB::BigNum.from_lc(x)
    rescue
      @illegal = true
    end
  end

  def illegal?
    @illegal
  end


  def surrounds(other)
    @start_num <= other.start_num and @stop_num >= other.stop_num
  end

  def contains_int(int)
    @start_num <= int and @stop_num >= int
  end

  def self.new_from_nokogiri_node(n, topic_array)
    self.new(n.get(:start), n.get(:end), topic_array)
  end



end
