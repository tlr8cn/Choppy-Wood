extends Node

class_name NaturalTree

# root is a TreeNode
var root = null
var leaves = []
# key is treeNode ID; value is distance from closest leaf to that leaf with that ID
var closest_leaf_neighbors = {}

func _init(root):
	self.root = root
	pass

func set_root(root): 
	self.root = root
	pass

func get_root(): 
	return self.root

# search invokes the recursive search function
func search(id):
	if root != null:
		return search_recursively(id, root)
	return null

func search_recursively(id, node):
	if node == null: # base case: not found
		return null
		
	if node.id == id: # base case: node found
		return node
	
	# recursive case: search the children
	var children = node.get_node_children()
	for i in range(children.size()):
		return search_recursively(id, children[i])
	
	# no children
	return null

func add_leaf(leaf):
	self.leaves.push_back(leaf)
	for i in leaves.size():
		var current_leaf = leaves[i]
		var min_distance = 999999999
		for j in range(i+1, leaves.size()):
			var comparison_leaf = leaves[j]
			var distance = current_leaf.get_center_point().distance_to(comparison_leaf.get_center_point())
			if distance < min_distance:
				min_distance = distance
				self.closest_leaf_neighbors[current_leaf.get_id()] = distance
	pass

func get_closest_leaf_neighbors():
	return self.closest_leaf_neighbors

# dfs that returns 2d array of TreeNodes representing contiguous drawing routes
# the caller will loop through the array - cutting unchecked drawing at the end of each inner array
func dfs_for_branches():
	var ret = [] # will be a 2d array of branches
	ret.append([])
	var ret_indx = 0
	
	var stack = []
	stack.push_back(self.root)
	while stack.size() > 0: # while stack is not empty
		# pop
		var el = stack.pop_back()
		# Stack may contain same vertex twice. So we need to print the popped item only
		# if it is not visited.
		if !el.get_visited():
			# set visited to true
			el.set_visited(true)
			# add to the return array
			ret[ret_indx].append(el)
			# if this is a leaf, we want to add a new branch to the return array
			if el.get_is_leaf():
				ret.append([])
				ret_indx += 1
			# After visiting, add to the array we'll return
		
		# the trick is to add nodes in reverse order
		var children = el.get_node_children()
		for i in range(children.size()-1, -1, -1):
			var child = children[i]
			if !child.get_visited():
				stack.push_back(child)
		
	return ret

func push(parent_id, node):
	var parent = search(parent_id)
	if parent == null:
		print("could not find parent: ", parent_id)
		print("tree:")
		self.print(self.root)
		pass
	parent.append_child(node)
	pass

# print all nodes in the tree
func print(node):
	if node == null: # base case: not found
		return null
	
	print(node.id, "-")
	
	# print the children
	var children = node.get_node_children()
	for i in range(children.size()):
		print(children[i])
	
	# no children
	return

func get_leaves():
	return self.leaves

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
