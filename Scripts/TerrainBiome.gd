extends Node

class_name TerrainBiome

var west_boundary = 0 # -z
var north_boundary = 0 # +x
var east_boundary = 0 # z
var south_boundary = 0 # -x

var i_array
var biome_settings

# Called when the node enters the scene tree for the first time.
func _init(west_boundary, north_boundary, east_boundary, south_boundary, biome_settings, i_array):
	self.west_boundary = west_boundary
	self.north_boundary = north_boundary
	self.east_boundary = east_boundary
	self.south_boundary = south_boundary
	self.biome_settings = biome_settings
	self.i_array = i_array
	pass

func get_west_boundary():
	return west_boundary

func get_north_boundary():
	return north_boundary

func get_east_boundary():
	return east_boundary

func get_south_boundary():
	return south_boundary

func get_i_array():
	return i_array

func get_biome_settings():
	return biome_settings
