extends Node

class_name BiomeSettings

var type
var height_factor
var height_range
var height_map # 2D array, not an actual map
var height_map_rotation
var num_height_increments = 5
var tree_generators = []

# Called when the node enters the scene tree for the first time.
func _init(type,tree_generators,height_range,height_map,height_map_rotation=0.0):
	self.type = type
	self.tree_generators = tree_generators
	self.height_range = height_range
	self.height_map = height_map
	
	self.height_map_rotation = height_map_rotation
	if height_map_rotation > 0:
		rotate_height_map(height_map_rotation)
	pass

func get_height_range():
	return height_range

func get_height_map():
	return height_map

func get_num_height_increments():
	return num_height_increments

func get_type():
	return type

func get_tree_generators():
	return tree_generators

func set_height_map_rotation(height_map_rotation):
	self.height_map_rotation = height_map_rotation
	if height_map_rotation > 0:
		rotate_height_map(height_map_rotation)
	pass

# rotates height map 90 degrees counter clockwise
# provided rotation must be a multiple of 90
func rotate_height_map(rotation):
	if rotation % 90 != 0:
		return
	while rotation > 0:
		rotate_90_counter_clockwise()
		rotation -= 90
	pass

func rotate_90_counter_clockwise():
	var n = height_map.size()
	for x in range(0, int(n / 2)):
		# Consider elements in group
		# of 4 in current square
		for y in range(x, n-x-1):
			var temp = height_map[x][y]
			# move values from right to top
			height_map[x][y] = height_map[y][n-1-x]
			# move values from bottom to right
			height_map[y][n-1-x] = height_map[n-1-x][n-1-y]
			# move values from left to bottom
			height_map[n-1-x][n-1-y] = height_map[n-1-y][x]
			# assign temp to left
			height_map[n-1-y][x] = temp
		
	pass
