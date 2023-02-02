extends Node

class_name BiomeSettings

var height_factor

# Called when the node enters the scene tree for the first time.
func _init(height_factor=10.0):
	self.height_factor = height_factor
	pass

func get_height_factor():
	return height_factor
