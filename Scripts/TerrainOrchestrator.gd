extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var rng = RandomNumberGenerator.new()
# TODO: might be able to delete this scene
#onready var chunk = load("res://Scenes/TerrainChunk.tscn")
var tree_likelihood = 10

var num_chunks = 1
var cube_width = 256
var cube_depth = 256
var cube_height = 256
var biome_divisions = 4 # total biomes = biome_divisions^2
#var chunk_size = 64

var chunk_grid = []

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	var noise_seed = rng.randi()
	
	var this_chunk = TerrainChunk.new(noise_seed, biome_divisions, cube_width, cube_depth, cube_height, tree_likelihood)
	this_chunk.transform.origin = Vector3(0.0, 0.0, 0.0)
	add_child(this_chunk)
	pass # Replace with function body.
