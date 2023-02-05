extends Node

class_name BiomeSettingsManager

var default_biome_settings
var foothills_biome_settings
var mountain_biome_settings

func _init():
	
	var default_height_map = [
		[3, 3, 3, 3, 3, 3, 3, 3],
		[3, 2, 2, 2, 2, 2, 2, 3],
		[3, 2, 1, 1, 1, 1, 2, 3],
		[3, 2, 1, 1, 1, 1, 2, 3],
		[3, 2, 1, 1, 1, 1, 2, 3],
		[3, 2, 1, 1, 1, 1, 2, 3],
		[3, 2, 2, 2, 2, 2, 2, 3],
		[3, 3, 3, 3, 3, 3, 3, 3]
	]
	self.default_biome_settings = BiomeSettings.new(default_height_map, Vector2(13.0, 15.0), 8.0)
	
	# TODO will likely need to write an algorithm to rotate a square array 90 degrees
	var foothills_height_map = [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[2, 2, 2, 2, 2, 2, 2, 1],
		[3, 2, 2, 2, 2, 2, 2, 1],
		[3, 3, 2, 2, 2, 2, 2, 1],
		[3, 3, 3, 3, 2, 2, 2, 1],
		[3, 3, 3, 3, 3, 2, 2, 1],
		[3, 3, 3, 3, 3, 2, 2, 1],
		[3, 3, 3, 3, 3, 3, 2, 1]
	]
	self.foothills_biome_settings = BiomeSettings.new(foothills_height_map, Vector2(15.0, 17.0), 11.0)
	
	var mountain_height_map = [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 2, 2, 2, 2, 2, 2, 1],
		[1, 2, 3, 3, 3, 3, 2, 1],
		[1, 2, 3, 3, 3, 3, 2, 1],
		[1, 2, 3, 3, 3, 3, 2, 1],
		[1, 2, 3, 3, 2, 3, 2, 1],
		[1, 2, 2, 2, 2, 2, 2, 1],
		[1, 1, 1, 1, 1, 1, 1, 1]
	]
	self.mountain_biome_settings = BiomeSettings.new(mountain_height_map, Vector2(17.0, 19.0), 15.0)
	pass

func get_default_biome_settings():
	return default_biome_settings

func get_mountain_biome_settings():
	return mountain_biome_settings

func get_foothills_biome_settings():
	return foothills_biome_settings
