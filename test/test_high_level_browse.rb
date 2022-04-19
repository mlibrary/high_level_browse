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

