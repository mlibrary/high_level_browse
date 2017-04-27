require 'benchmark/ips'
$:.unshift '../lib'
$:.unshift '.'


# On my laptop under normal load (e.g., not very scientific at all)
# I get the following running in a single thread
#   ruby 2.3              ~8500 lookups/second
#   ruby 2.4              ~9100 lookups/second
#   jruby 9               ~2kk  lookups/second
#   jruby 9, old HLB.jar  ~6500 lookups/second
#
# The old HLB.jar has a different/worse algorithm, but is of
# interest because it's what I'm writing this to replace.

# umich_traject holds .jar files with the old java implementation; see
# https://github.com/hathitrust/ht_traject/tree/9e8d414fd9bb2c79e243d289c4d39c05d2de27e5/lib/umich_traject
#

TEST_OLD_STUFF = defined? JRUBY_VERSION and Dir.exist?('./umich_traject')
if TEST_OLD_STUFF
  puts "Loading old HLB3.jar stuff"
  require 'umich_traject/jackson-core-asl-1.4.3.jar'
  require 'umich_traject/jackson-mapper-asl-1.4.3.jar'
  require 'umich_traject/apache-solr-umichnormalizers.jar'
  require 'umich_traject/HLB3.jar'
  java_import Java::edu.umich.lib.hlb::HLB
  puts "Initializing HLB"
  HLB.initialize()
end

require 'high_level_browse'

h = HighLevelBrowse.load(dir: '.')

cns = File.read('call_numbers.txt').split(/\n/).cycle

puts RUBY_DESCRIPTION

total = 0
Benchmark.ips do |x|
  x.config(:time => 15, :warmup => 5)
  x.report("HLB lookups") do
    total += h[cns.next].count
  end

  if TEST_OLD_STUFF
    total = 0
    x.report("Old java lookups") do
      total += HLB.categories(cns.next).to_a.count
    end
    x.compare!
  end
end
