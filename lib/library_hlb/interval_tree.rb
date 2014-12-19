require 'library_hlb/red_black_tree'

# An interval tree consist of a bunch of keys that
#  * have a begin and endoint (e.g., they represent ranges)
#  * when sorted, are sorted by the begin (r.begin <=> s.begin)
#  * respond to #begin and #end to get the two endpoints
#


class RedBlackTree::Node
  # What the maximum of [self.end, left.end, right.end]?
  attr_accessor :max_endpoint

  # Compute the max endpoints
  def set_max_endpoints
    if self.nil?
      @max_endpoint = 0
    else
      @max_endpoint = [key.end, @left.set_max_endpoints, @right.set_max_endpoints].max
    end
    @max_endpoint
  end

  # Find all the nodes that contain the given transformed key

  def keys_that_cover(tk)
    return [] if self.nil? or @max_endpoint < tk
    return left.keys_that_cover(k) unless key.begin <= tk
    rv = []
    rv << key if key.end >= tk
    return rv.concat(left.keys_that_cover(tk)).concat(right.keys_that_cover(tk))
  end

end

class Library::HLB::IntervalTree < RedBlackTree

  class Node < RedBlackTree::Node



  end


  # Allow us to pass in the type of node to create keys from
  def initialize(keyclass = Library::HLB::IntervalTree::Node)
    super()
    @keyclass = keyclass
  end

  # Redefine add to allow any number of args
  # and use our internal nodeclass
  def add(*x)
    k = @keyclass.new(*x)
    insert Node.new(k)
  end

  def keys_that_cover(tk)
    @root.keys_that_cover(tk)
  end


  def set_max_endpoints
    @root.set_max_endpoints
    nil
  end

end


