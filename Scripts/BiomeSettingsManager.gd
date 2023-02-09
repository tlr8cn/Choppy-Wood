extends Node

class_name BiomeSettingsManager

var default_biome_settings
var foothills_biome_settings
var foothills_corner_biome_settings
var mountain_biome_settings

var original_tree_generator = load("res://Scenes/NaturalTree.tscn")
var magnolia_tree_generator = load("res://Scenes/NaturalTree_Magnolia.tscn")

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
	[5, 5, 5, 5, 5, 5, 5, 5],
	[5, 4, 4, 4, 4, 4, 4, 4],
	[5, 4, 3, 3, 3, 3, 3, 3],
	[5, 4, 3, 2, 2, 2, 2, 2],
	[5, 4, 3, 2, 1, 1, 1, 1],
	[5, 4, 3, 2, 1, 0, 0, 0],
	[5, 4, 3, 2, 1, 0, 0, 0],
	[5, 4, 3, 2, 1, 0, 0, 0],
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

func _init():
	self.default_biome_settings = BiomeSettings.new("DEFAULT", [original_tree_generator], default_height_range, default_height_map)
	self.foothills_biome_settings = BiomeSettings.new("FOOTHILLS", [original_tree_generator, magnolia_tree_generator], foothills_height_range, foothills_height_map)
	self.mountain_biome_settings = BiomeSettings.new("MOUNTAIN", [magnolia_tree_generator], mountain_height_range, mountain_height_map)
	self.foothills_corner_biome_settings = BiomeSettings.new("FOOTHILLS_CORNER", [original_tree_generator, magnolia_tree_generator], foothills_corner_height_range, foothills_corner_height_map)
	pass

func get_default_biome_settings():
	return default_biome_settings

func get_mountain_biome_settings():
	return mountain_biome_settings

func get_foothills_biome_settings():
	return foothills_biome_settings

func get_foothills_corner_biome_settings():
	return foothills_corner_biome_settings
