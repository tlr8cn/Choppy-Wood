extends Node

class_name TerrainBiome

var west_boundary = 0 # -z
var north_boundary = 0 # +x
var east_boundary = 0 # z
var south_boundary = 0 # -x

var west_edge = []
var north_edge = []
var east_edge = []
var south_edge = []

var west_neighbor = null
var north_neighbor = null
var east_neighbor = null
var south_neighbor = null

# TODO: also include the xz grid associated with the biome in this class
# on init, use that create a xz_height_map which has a specific height mapping for each vertex.
# For example, mountainous terrain could have a height map that has lower values around the edges 
# but higher towards the middle. Arranging the height map correctly could help with smoothing the edges or
# creating flat trails that wrap around a mountain
var i_array
var i_to_xz
var biome_settings

var biome_divisions
var division_x
var division_z

var width
var height

# Called when the node enters the scene tree for the first time.
func _init(west_boundary, north_boundary, east_boundary, south_boundary, biome_divisions, biome_settings, i_array, i_to_xz, division_x, division_z):
	self.west_boundary = west_boundary
	self.north_boundary = north_boundary
	self.east_boundary = east_boundary
	self.south_boundary = south_boundary
	self.biome_divisions = biome_divisions
	self.biome_settings = biome_settings
	self.i_array = i_array
	self.i_to_xz = i_to_xz
	for ii in range(i_array.size()):
		var i = i_array[ii]
		var xz = i_to_xz[i]
		var x = xz[0]
		var z = xz [1]
		if x >= west_boundary && x <= west_boundary:
			self.west_edge.push_back(i)
		elif x >= east_boundary  && x <= east_boundary:
			self.east_edge.push_back(i)
		if z >= north_boundary && x <= north_boundary:
			self.north_edge.push_back(i)
		elif z >= south_boundary && z <= south_boundary:
			self.south_edge.push_back(i)
	
	self.width = east_boundary - west_boundary
	self.height = north_boundary - south_boundary
	
	self.division_x = division_x
	self.division_z = division_z
	pass

func apply_height_smoothing(i):
	var biome_settings = get_biome_settings()
	var new_height_factor = biome_settings.get_height_factor()
	if self.west_edge.has(i) && self.west_neighbor != null:
		var west_biome_settings = self.west_neighbor.get_biome_settings()
		var west_height_factor = west_biome_settings.get_height_factor()
		new_height_factor = (west_height_factor + new_height_factor)/2
	elif self.east_edge.has(i) && self.east_neighbor != null:
		var east_biome_settings = self.east_neighbor.get_biome_settings()
		var east_height_factor = east_biome_settings.get_height_factor()
		new_height_factor = (east_height_factor + new_height_factor)/2
	if self.north_edge.has(i) && self.north_neighbor != null:
		var north_biome_settings = self.north_neighbor.get_biome_settings()
		var north_height_factor = north_biome_settings.get_height_factor()
		new_height_factor = (north_height_factor + new_height_factor)/2
	elif self.south_edge.has(i) && self.south_neighbor != null:
		var south_biome_settings = self.south_neighbor.get_biome_settings()
		var south_height_factor = south_biome_settings.get_height_factor()
		new_height_factor = (south_height_factor + new_height_factor)/2
	
	return new_height_factor

func get_height_factor_for_index(i):
	var biome_settings = get_biome_settings()
	var height_range = biome_settings.get_height_range()
	var height_map = biome_settings.get_height_map()
	var xz = i_to_xz[i]
	var x = reduce(xz[0], width)
	var z = reduce(xz[1], height)
	var height_x = floor((float(x) / (float(width) / float(height_map.size()))))
	var height_z = floor((float(z) / (float(height) / float(height_map.size()))))
	var height_map_val = height_map[height_x][height_z]
	var height_factor
	if height_map_val == 1:
		height_factor = height_range.x
	elif height_map_val == 2:
		height_factor = (height_range.y + height_range.x)/2.0
	elif height_map_val == 3:
		height_factor = height_range.y
	print(height_factor)
	return height_factor

func get_west_boundary():
	return west_boundary

func get_north_boundary():
	return north_boundary

func get_east_boundary():
	return east_boundary

func get_south_boundary():
	return south_boundary

func get_width():
	return width

func get_height():
	return height

func get_i_array():
	return i_array

func get_biome_settings():
	return biome_settings

func get_west_edge():
	return west_edge

func get_north_edge():
	return north_edge

func get_east_edge():
	return east_edge

func get_south_edge():
	return south_edge

func get_west_neighbor():
	return west_neighbor

func get_north_neighbor():
	return north_neighbor

func get_east_neighbor():
	return east_neighbor

func get_south_neighbor():
	return south_neighbor

func set_west_neighbor(west_neighbor):
	self.west_neighbor = west_neighbor

func set_north_neighbor(north_neighbor):
	self.north_neighbor = north_neighbor

func set_east_neighbor(east_neighbor):
	self.east_neighbor = east_neighbor

func set_south_neighbor(south_neighbor):
	self.south_neighbor = south_neighbor

func reduce(index, upper_bound):
	var new_index = index
	while new_index >= upper_bound:
		new_index -= upper_bound
	return new_index
