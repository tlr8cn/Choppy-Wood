extends Node

class_name BiomeSettingsManager

var default_biome_settings
var foothills_biome_settings
var foothills_corner_biome_settings
var mountain_biome_settings

func _init():
	self.default_biome_settings = BiomeSettings.new("DEFAULT")
	self.foothills_biome_settings = BiomeSettings.new("FOOTHILLS")
	self.mountain_biome_settings = BiomeSettings.new("MOUNTAIN")
	self.foothills_corner_biome_settings = BiomeSettings.new("FOOTHILLS_CORNER")
	pass

func get_default_biome_settings():
	return default_biome_settings

func get_mountain_biome_settings():
	return mountain_biome_settings

func get_foothills_biome_settings():
	return foothills_biome_settings
