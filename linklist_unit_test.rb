require 'test/unit'
 
class Node
	attr_accessor :value
	attr_accessor :next

	def initialize(value)
		self.value = value
	end

	def add(node)
		n = self
		until n.next.nil?
			n = n.next
		end 
		n.next = node
	end
 
	def self.from_array(a)
		return nil if a.nil? || a.size == 0
		list = nil
		a.each do |v|
			if list.nil?
				list =  Node.new(v)
			else
				list.add(Node.new(v))
			end
		end
		list
	end

	def to_array
		arr = []
		n = self
		until n.nil?
			arr.push(n.value)
			n = n.next
		end
		arr
	end
end
 
# reverse link list in recursion
def reverse_list_r(list)
	# base case
	if list.nil? || list.next.nil? 
		return list
	end
	
	tail = reverse_list_r(list.next)
	clone = tail
	until clone.next.nil?
		clone = clone.next
	end
	
	clone.next = list
	list.next = nil
	tail
end
# reverse link list
def reverse_list(list)
	p_node = list
	p_reverse_head = p_prev = nil
	
	until p_node.nil?
		p_next = p_node.next
		p_reverse_head = p_node if p_next.nil?
		
		p_node.next = p_prev
		p_prev = p_node
		p_node = p_next
	end
	p_reverse_head
end
 
class TestAlgorithm < Test::Unit::TestCase
	  def test_from_array
		list = Node.from_array([1, 2, 3])
		assert_equal(1, list.value)
		assert_equal(2, list.next.value)
		assert_equal(3, list.next.next.value)
	  end
	 
	  def test_to_array
		list = Node.new(3)
		list.add(Node.new(5))
		list.add(Node.new(7))
		assert_equal([3, 5, 7], list.to_array)
	  end
	   
	  def test_reverse_linked_list
		arr = []   
		assert_nil reverse_list_r(Node.from_array(arr))
		assert_nil reverse_list(Node.from_array(arr))
		
		arr = [1]   
		assert_equal(arr.reverse, reverse_list_r(Node.from_array(arr)).to_array)
		assert_equal(arr.reverse, reverse_list(Node.from_array(arr)).to_array)
		
		arr = [1, 2]  
		assert_equal(arr.reverse, reverse_list_r(Node.from_array(arr)).to_array)
		assert_equal(arr.reverse, reverse_list(Node.from_array(arr)).to_array)
		
		arr = [3, 1, 2]  
		assert_equal(arr.reverse, reverse_list_r(Node.from_array(arr)).to_array)
		assert_equal(arr.reverse, reverse_list(Node.from_array(arr)).to_array)
		
		arr = [5, 3, 1, 2]  
		assert_equal(arr.reverse, reverse_list_r(Node.from_array(arr)).to_array)
		assert_equal(arr.reverse, reverse_list(Node.from_array(arr)).to_array)
		
		arr = [5, 3, 1, 2, 7]  
		assert_equal(arr.reverse, reverse_list_r(Node.from_array(arr)).to_array)
		assert_equal(arr.reverse, reverse_list(Node.from_array(arr)).to_array)		
	  end
 end