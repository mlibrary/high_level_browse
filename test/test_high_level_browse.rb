require 'minitest_helper'

require 'json'
TESTDIR = File.expand_path(File.dirname(__FILE__))

describe "loads" do
  it "loads" do
    assert true
  end

  it "has a version" do
    HighLevelBrowse::VERSION.wont_be_nil
  end
end

describe "Works the same as before" do
  it "gets the same output for 30k randomly chosen call numbers" do
    h = HighLevelBrowse.fetch_and_save(dir: TESTDIR)
    JSON.load(File.open(File.join(TESTDIR, '30k_random_old_mappings.json'))).each do |rec|
      cn = rec['cn'].strip
      newcats = h[cn]
      next if rec['jar'].empty?
      assert_equal [cn, rec['jar'].sort], [rec['cn'], newcats.sort]
    end

  end
end
