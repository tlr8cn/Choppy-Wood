extends Node

class_name BiomeSettings

var type
var height_factor
var height_range
var height_map # 2D array, not an actual map
var height_map_rotation
var num_height_increments = 5

var default_height_map = [
	[5, 5, 5, 5, 5, 5, 5, 5],
	[5, 4, 4, 4, 4, 4, 4, 5],
	[5, 4, 3, 3, 3, 3, 4, 5],
	[5, 4, 3, 3, 3, 3, 4, 5],
	[5, 4, 3, 3, 3, 3, 4, 5],
	[5, 4, 3, 3, 3, 3, 4, 5],
	[5, 4, 4, 4, 4, 4, 4, 5],
	[5, 5, 5, 5, 5, 5, 5, 5]
]
var default_height_range = Vector2(8.0, 16.0)

var foothills_height_map = [
	[5, 5, 5, 5, 5, 5, 5, 5],
	[5, 5, 5, 5, 5, 5, 5, 5],
	[4, 4, 4, 4, 4, 4, 4, 4],
	[3, 3, 3, 3, 3, 3, 3, 3],
	[2, 2, 2, 2, 2, 2, 2, 2],
	[1, 1, 1, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
]
var foothills_height_range = Vector2(16.0, 32.0)

var foothills_corner_height_map = [
	[5, 5, 5, 5, 4, 3, 2, 1],
	[5, 4, 4, 4, 3, 2, 1, 0],
	[5, 4, 3, 3, 2, 1, 0, 0],
	[5, 4, 3, 2, 1, 0, 0, 0],
	[4, 3, 2, 1, 0, 0, 0, 0],
	[3, 2, 1, 0, 0, 0, 0, 0],
	[2, 1, 0, 0, 0, 0, 0, 0],
	[1, 0, 0, 0, 0, 0, 0, 0],
]
var foothills_corner_height_range = Vector2(16.0, 32.0)

var mountain_height_map = [
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 1, 1, 2, 2, 1, 1, 0],
	[0, 1, 3, 4, 4, 3, 1, 0],
	[0, 2, 4, 5, 5, 4, 2, 0],
	[0, 2, 4, 5, 5, 4, 2, 0],
	[0, 1, 3, 4, 4, 3, 1, 0],
	[0, 1, 1, 2, 2, 1, 1, 0],
	[0, 0, 0, 0, 0, 0, 0, 0]
]
var mountain_height_range = Vector2(32.0, 64.0)

# Called when the node enters the scene tree for the first time.
func _init(type, height_map_rotation=0.0):
	self.type = type
	if self.type == "DEFAULT":
		self.height_range = default_height_range
		self.height_map = default_height_map
	elif self.type == "FOOTHILLS":
		self.height_range = foothills_height_range
		self.height_map = foothills_height_map
	elif self.type == "MOUNTAIN":
		self.height_range = mountain_height_range
		self.height_map = mountain_height_map
	elif self.type == "FOOTHILLS_CORNER":
		self.height_range = foothills_corner_height_range
		self.height_map = foothills_corner_height_map
	
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
