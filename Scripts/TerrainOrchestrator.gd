extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var rng = RandomNumberGenerator.new()
# TODO: might be able to delete this scene
#onready var chunk = load("res://Scenes/TerrainChunk.tscn")

# TODO: try one big plane where sections are recalcalated based on proximity?
var num_chunks = 1
var cube_width = 64
var cube_depth = 64
var cube_height = 64
var biome_divisions = 2 # total biomes = biome_divisions^2
#var chunk_size = 64

var chunk_grid = []

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	var noise_seed = rng.randi()
	
	var this_chunk = TerrainChunk.new(noise_seed, biome_divisions, cube_width, cube_depth, cube_height)
	this_chunk.transform.origin = Vector3(0.0, 0.0, 0.0)
	add_child(this_chunk)
	pass # Replace with function body.
