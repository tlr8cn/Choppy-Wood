extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var rng = RandomNumberGenerator.new()
# TODO: might be able to delete this scene
#onready var chunk = load("res://Scenes/TerrainChunk.tscn")

# TODO: try one big plane where sections are recalcalated based on proximity?
var num_chunks = 1
var plane_width = 256
var plane_depth = 256
var biome_divisions = 2 # total biomes = biome_divisions^2
#var chunk_size = 64

var chunk_grid = []

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	var noise_seed = rng.randi()
	var x_position = 0.0
	var z_position = 0.0
	
	#var loop_bound = sqrt(num_chunks)
	for i in num_chunks:
		chunk_grid.push_back([])
		for j in num_chunks:
			var this_chunk = TerrainChunk.new(noise_seed, biome_divisions, plane_width, plane_depth)
			this_chunk.transform.origin = Vector3(x_position, 0.0, z_position)
			print(this_chunk.transform.origin)
			chunk_grid[i].push_back(this_chunk)
			z_position = z_position + plane_depth
		x_position = x_position + plane_depth
		z_position = 0.0
		
	for i in chunk_grid.size():
		for j in chunk_grid[i].size():
			add_child(chunk_grid[i][j])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
