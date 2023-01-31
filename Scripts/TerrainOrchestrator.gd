extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var rng = RandomNumberGenerator.new()
# TODO: might be able to delete this scene
#onready var chunk = load("res://Scenes/TerrainChunk.tscn")

# TODO: try one big plane where sections are recalcalated based on proximity?
var num_chunks = 4
var plane_width = 64
var plane_depth = 64
#var chunk_size = 64

var chunk_grid = []

var generation_queue = []

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	var noise_seed = rng.randi()
	var x_position = 0.0
	var z_position = 0.0
	
	var width_in_chunks = int(sqrt(num_chunks))
	for i in width_in_chunks:
		chunk_grid.push_back([])
		for j in width_in_chunks:
			chunk_grid[i].push_back(null)
	
	generation_queue.push_back(Vector2(0, 0))
	while generation_queue.size() > 0:
		var chunk_index = generation_queue.pop_front()
		x_position = chunk_index.x*plane_depth
		z_position = chunk_index.y*plane_depth
		var neighboring_sides_map = {
			"WEST": null,
			"SOUTH": null
		}
		
		if chunk_index.x > 0:
			var west_chunk = chunk_grid[int(chunk_index.x) - 1][int(chunk_index.y)]
			neighboring_sides_map["WEST"] = west_chunk.get_east_side()
		if chunk_index.y > 0:
			var south_chunk = chunk_grid[int(chunk_index.x)][int(chunk_index.y) - 1]
			neighboring_sides_map["SOUTH"] = south_chunk.get_north_side()
		
		var this_chunk = TerrainChunk.new(noise_seed, neighboring_sides_map, Vector2(x_position, z_position), plane_width, plane_depth)
		this_chunk.transform.origin = Vector3(x_position, 0.0, z_position)
		chunk_grid[int(chunk_index.x)][int(chunk_index.y)] = this_chunk
		if chunk_index.x + 1 < width_in_chunks && chunk_grid[int(chunk_index.x) + 1][int(chunk_index.y)] == null:
			generation_queue.push_back(Vector2(chunk_index.x + 1, chunk_index.y))
		if chunk_index.y + 1 < width_in_chunks && chunk_grid[int(chunk_index.x)][int(chunk_index.y) + 1] == null:
			generation_queue.push_back(Vector2(chunk_index.x, chunk_index.y + 1))
	
	for i in chunk_grid.size():
		for j in chunk_grid[i].size():
			add_child(chunk_grid[i][j])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
