$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# Both oga and minitest have stupid warnings that I don't want to
# hear about

verbose = $VERBOSE
$VERBOSE = nil
require 'oga'
require 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
$VERBOSE = verbose

require 'high_level_browse'
