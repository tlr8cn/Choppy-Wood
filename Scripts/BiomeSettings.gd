extends Node

class_name BiomeSettings

var height_factor
var height_range
var height_map # 2D array, not an actual map

# Called when the node enters the scene tree for the first time.
func _init(height_map, height_range=Vector2(8.0, 12.0), height_factor=10.0):
	self.height_factor = height_factor
	self.height_range = height_range
	self.height_map = height_map
	pass

func get_height_factor():
	return height_factor

func get_height_range():
	return height_range

func get_height_map():
	return height_map
