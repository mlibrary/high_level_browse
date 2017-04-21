require 'high_level_browse/errors'
require 'lc_callnumber'

module HighLevelBrowse::BigNum
  # We'll assume five bits for each letter
  F_LET = '%05b'

  #...and 17 for each five-digit number
  F_NUM = '%017b'

  # We're assuming a max form of AAA99999.99999 A99999

  BINARY_FORMAT = (F_LET * 3) << (F_NUM * 2) << (F_LET) << (F_NUM)

  # Turn a LC number -- just the letters, digits, and first cutter -- into
  # an integer.
  #
  # We pack things in pretty tightly here, which is a bit slower but results
  # in regular 64-bit Fixnums for everything but the ZZ range of call numbers
  # This makes comparisons pretty fast.
  #
  # We'll raise an IllegalLC argument if the lc isn't valid
  def self.from_lc(x)
    lc = LCCallNumber.parse(x)
    raise HighLevelBrowse::IllegalLC.new(x) unless lc.valid?

    letters = ('%3s' % lc.letters).gsub(' ', 64.chr).chars.map(&:ord).map{|x| x - 64}
    digits = ('%11.5f' % lc.digits).split('.').map(&:to_i)
    digits[1] ||= 0
    cutter = lc.firstcutter || LCCallNumber::Cutter.new(' ', 0)
    cutletter = cutter.letter.upcase.gsub(' ', 64.chr).chars.map(&:ord).map{|x| x - 64}
    cutdigits = cutter.digits.to_i
    (BINARY_FORMAT % [letters, digits, cutletter, cutdigits].flatten).to_i(2)
  end


end
