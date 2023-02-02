extends Node

class_name BiomeSettingsManager

var default_biome_settings
var mountain_biome_settings

# Called when the node enters the scene tree for the first time.
func _init():
	self.default_biome_settings = BiomeSettings.new(10.0)
	self.mountain_biome_settings = BiomeSettings.new(75.0)
	pass

func get_default_biome_settings():
	return default_biome_settings
	pass

func get_mountain_biome_settings():
	return mountain_biome_settings
	pass
