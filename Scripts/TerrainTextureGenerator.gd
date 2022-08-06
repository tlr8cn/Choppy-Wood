extends Node

class_name TerrainTextureGenerator

var rng = RandomNumberGenerator.new()

# the texture image to be generated
var terrain_image
# the resultant texture
var terrain_texture

# an enumeration of tile types for generating the texture
enum TileType {
	PURE_GRASS,
	GRASS_SURROUNDED, #(3, 3)
	GRASS_BLEED_UP, #(3, 1)
	GRASS_BLEED_DOWN, # (3, 5)
	GRASS_BLEED_LEFT, # (5, 2)
	GRASS_BLEED_RIGHT, # (1, 2)
	GRASS_CORNER_TOP_LEFT # (1, 1)
	GRASS_CORNER_BOTTOM_LEFT, # (1, 5)
	GRASS_CORNER_BOTTOM_RIGHT, # (5, 5)
	GRASS_CORNER_TOP_RIGHT, # (5, 1)
	GRASS_MIDDLE_HORIZONTAL, # (3, 1)
	GRASS_MIDDLE_VERTICAL,  # (1, 3)
	
	PURE_DIRT,
	DIRT_BLEED_UP, # (3, 6)
	DIRT_BLEED_DOWN, # (3, 0)
	DIRT_BLEED_LEFT, # (6, 3)
	DIRT_BLEED_RIGHT, # (0, 3)
	
	DIRT_CORNER_TOP_LEFT # (2, 2)
	DIRT_CORNER_BOTTOM_LEFT, # (2, 4)
	DIRT_CORNER_BOTTOM_RIGHT, # (4, 2)
	DIRT_CORNER_TOP_RIGHT, # (4, 4)
	DIRT_MIDDLE_HORIZONTAL, # (3, 4)
	DIRT_MIDDLE_VERTICAL,  # (2, 3)
	# TODO: Will also need grass middle
}

# TODO: Create a mapping of TileTypes to tuples representing the index of the 
# tile's top-left corner on the bitmap
var type_map = {
	TileType.GRASS_BLEED_UP: [3, 1],
	TileType.DIRT_BLEED_DOWN: [3, 0],
	TileType.GRASS_BLEED_DOWN: [3, 5],
	TileType.DIRT_BLEED_UP: [3, 6],
	TileType.GRASS_BLEED_LEFT: [5, 2],
	TileType.DIRT_BLEED_RIGHT: [0, 3],
	TileType.GRASS_BLEED_RIGHT: [1, 2],
	TileType.DIRT_BLEED_LEFT: [6, 3],
	TileType.DIRT_CORNER_TOP_LEFT: [2, 2],
	TileType.DIRT_CORNER_BOTTOM_LEFT: [2, 4],
	TileType.DIRT_CORNER_BOTTOM_RIGHT: [4, 2],
	TileType.DIRT_CORNER_TOP_RIGHT: [4, 4],
	TileType.DIRT_MIDDLE_HORIZONTAL: [3, 4],
	TileType.DIRT_MIDDLE_VERTICAL: [2, 3],
	TileType.GRASS_CORNER_TOP_LEFT: [1, 1],
	TileType.GRASS_CORNER_BOTTOM_LEFT: [1, 5],
	TileType.GRASS_CORNER_BOTTOM_RIGHT: [5, 5],
	TileType.GRASS_CORNER_TOP_RIGHT: [5, 1],
	TileType.GRASS_MIDDLE_HORIZONTAL: [3, 1],
	TileType.GRASS_MIDDLE_VERTICAL: [1, 3],
	TileType.GRASS_SURROUNDED: [3, 3]
}

func _init(image_width, image_height):
	rng.randomize()
	terrain_texture = ImageTexture.new()
	terrain_image = Image.new()
	terrain_image.create(image_width, image_height, false, Image.FORMAT_RGBA8)
	var sheet = Image.new()
	sheet.load("res://spritesheets/terrain-spritesheet.png")
	var pure_grass_image = Image.new()
	pure_grass_image.load("res://textures/grass_texture.png")
	var pure_dirt_image = Image.new()
	pure_dirt_image.load("res://textures/dirt_texture1.png")
	
	var map_size = image_width/128
	# texture_map is a 2D array of TileTypes
	var texture_map = init_texture_map(map_size)
	var grass_percent_chance = 50 # will change
	
	for i in range(texture_map.size()):
		for j in range(texture_map[i].size()):
			var num_neighbors = get_tile_neighbors(texture_map, i, j)
			var num_grass_neighbors = num_neighbors[0]
			var num_dirt_neighbors = num_neighbors[1]
			
			grass_percent_chance += num_grass_neighbors
			if grass_percent_chance > 90:
				grass_percent_chance = 90
			
			grass_percent_chance -= num_dirt_neighbors
			if grass_percent_chance < 10:
				grass_percent_chance = 10
			
			# roll to determine which texture to pick
			var roll = rng.randi_range(0, 100)
			if roll <= grass_percent_chance:
				# begin as a normal grass tile
				texture_map[i][j] = TileType.PURE_GRASS
			else:
				# begin as a normal dirt tile
				texture_map[i][j] = TileType.PURE_DIRT
			
		
	# TODO: write smoothing loop
	var tex_x = 0
	var current_tile_type
	for i in range(texture_map.size()):
		var tex_y = 0
		for j in range(texture_map[i].size()):
			current_tile_type = texture_map[i][j]
			var is_grass = false
			if current_tile_type == TileType.PURE_GRASS:
				is_grass = true
			
			if is_grass:
				var dirt_count = 0
				#left
				if i > 0 && !tile_is_grass(texture_map[i-1][j]):
					dirt_count += 1
					current_tile_type = TileType.GRASS_BLEED_LEFT
				#up
				if j > 0  && !tile_is_grass(texture_map[i][j-1]):
					dirt_count += 1
					if dirt_count == 1:
						current_tile_type = TileType.GRASS_BLEED_UP
					elif dirt_count == 2:
						current_tile_type = TileType.GRASS_CORNER_TOP_LEFT
				#right
				if i < texture_map.size() - 1 && !tile_is_grass(texture_map[i+1][j]):
					dirt_count += 1
					if current_tile_type == TileType.GRASS_BLEED_LEFT:
						current_tile_type = TileType.GRASS_MIDDLE_VERTICAL
					elif current_tile_type == TileType.GRASS_BLEED_UP:
						current_tile_type = TileType.GRASS_CORNER_TOP_RIGHT
					else:
						current_tile_type = TileType.GRASS_BLEED_RIGHT
				#down
				if j < texture_map[i].size() - 1 && !tile_is_grass(texture_map[i][j+1]):
					dirt_count += 1
					if dirt_count == 4:
						current_tile_type = TileType.GRASS_SURROUNDED
					elif current_tile_type == TileType.GRASS_BLEED_RIGHT:
						current_tile_type = TileType.GRASS_CORNER_BOTTOM_RIGHT
					elif current_tile_type == TileType.GRASS_BLEED_UP:
						current_tile_type = TileType.GRASS_MIDDLE_HORIZONTAL
					else:
						current_tile_type = TileType.GRASS_BLEED_DOWN
					#TODO: work in bottom left corner
			else:
				var grass_count = 0
				#left
				if i > 0 && tile_is_grass(texture_map[i-1][j]):
					grass_count += 1
					current_tile_type = TileType.DIRT_BLEED_LEFT
				#up
				if j > 0  && tile_is_grass(texture_map[i][j-1]):
					grass_count += 1
					if grass_count == 1:
						current_tile_type = TileType.DIRT_BLEED_UP
					elif grass_count == 2:
						current_tile_type = TileType.DIRT_CORNER_TOP_LEFT
				#right
				if i < texture_map.size() - 1 && tile_is_grass(texture_map[i+1][j]):
					grass_count += 1
					if current_tile_type == TileType.DIRT_BLEED_LEFT:
						current_tile_type = TileType.DIRT_MIDDLE_VERTICAL
					elif current_tile_type == TileType.DIRT_BLEED_UP:
						current_tile_type = TileType.DIRT_CORNER_TOP_RIGHT
					else:
						current_tile_type = TileType.DIRT_BLEED_RIGHT
				#down
				if j < texture_map[i].size() - 1 && tile_is_grass(texture_map[i][j+1]):
					grass_count += 1
					if current_tile_type == TileType.DIRT_BLEED_RIGHT:
						current_tile_type = TileType.DIRT_CORNER_BOTTOM_RIGHT
					elif current_tile_type == TileType.DIRT_BLEED_UP:
						current_tile_type = TileType.DIRT_MIDDLE_HORIZONTAL
					else:
						current_tile_type = TileType.DIRT_BLEED_DOWN
			
			if current_tile_type == TileType.PURE_GRASS:
				terrain_image.blit_rect(pure_grass_image, Rect2(0,0,128,128), Vector2(tex_x,tex_y))
			elif current_tile_type == TileType.PURE_DIRT:
				terrain_image.blit_rect(pure_dirt_image, Rect2(0,0,128,128), Vector2(tex_x,tex_y))
			else:
				var grid_slice = type_map[current_tile_type]
				var grid_coord = Vector2(grid_slice[0], grid_slice[1])
				terrain_image.blit_rect(sheet, Rect2(128*grid_coord.x, 128*grid_coord.y, 128, 128), Vector2(tex_x,tex_y))
			
			tex_y += 128
		tex_x += 128
	
	#terrain_image.unlock()
	#terrain_image.save_png("res://test_terrain.png")
	
	terrain_texture.create_from_image(terrain_image)
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_terrain_texture():
	return self.terrain_texture

# @param coord_x is an int representing x position on the grid
# @param coord_y is an int representing y position on the grid
# @param texture_map is the map of texture types
# returns an array; 0 index = number of adjacent grass tiles; 1 index = adjacent dirt tiles
func get_tile_neighbors(texture_map, coord_x, coord_y):
	var grass_count = 0
	var dirt_count = 0
	# check right
	if coord_x < texture_map.size() - 1 && texture_map[coord_x+1][coord_y] > -1:
		if tile_is_grass(texture_map[coord_x+1][coord_y]):
			grass_count += 1
		else:
			dirt_count += 1
	# check left
	if coord_x > 0 && texture_map[coord_x-1][coord_y] > -1:
		if tile_is_grass(texture_map[coord_x-1][coord_y]):
			grass_count += 1
		else:
			dirt_count += 1
	# check down
	if coord_y < texture_map[coord_x].size() - 1 && texture_map[coord_x][coord_y+1] > -1:
		if tile_is_grass(texture_map[coord_x][coord_y+1]):
			grass_count += 1
		else:
			dirt_count += 1
	# check up
	if coord_y > 0 && texture_map[coord_x][coord_y-1] > -1:
		if tile_is_grass(texture_map[coord_x][coord_y-1]):
			grass_count += 1
		else:
			dirt_count += 1
	# check down, right
	if coord_x < texture_map.size() - 1 && coord_y < texture_map[coord_x].size() - 1 && texture_map[coord_x+1][coord_y+1] > -1:
		if tile_is_grass(texture_map[coord_x+1][coord_y+1]):
			grass_count += 1
		else:
			dirt_count += 1
	# check down, left
	if coord_x > 0 && coord_y < texture_map[coord_x].size() - 1 && texture_map[coord_x-1][coord_y+1] > -1:
		if tile_is_grass(texture_map[coord_x-1][coord_y+1]):
			grass_count += 1
		else:
			dirt_count += 1
	# check up, left
	if coord_x > 0 && coord_y > 0 && texture_map[coord_x-1][coord_y-1] > -1:
		if tile_is_grass(texture_map[coord_x-1][coord_y-1]):
			grass_count += 1
		else:
			dirt_count += 1
	# check up, right
	if coord_x < texture_map.size() - 1 && coord_y > 0 && texture_map[coord_x+1][coord_y-1] > -1:
		if tile_is_grass(texture_map[coord_x+1][coord_y-1]):
			grass_count += 1
		else:
			dirt_count += 1
	return [grass_count, dirt_count]
	
func tile_is_grass(tile_type):
	if tile_type == TileType.PURE_GRASS || tile_type == TileType.GRASS_BLEED_UP || tile_type == TileType.GRASS_BLEED_DOWN || tile_type == TileType.GRASS_BLEED_LEFT || tile_type == TileType.GRASS_BLEED_RIGHT || tile_type == TileType.GRASS_CORNER_TOP_LEFT || tile_type == TileType.GRASS_CORNER_BOTTOM_LEFT || tile_type == TileType.GRASS_CORNER_BOTTOM_RIGHT || tile_type == TileType.GRASS_CORNER_TOP_RIGHT || tile_type == TileType.GRASS_MIDDLE_HORIZONTAL || tile_type == TileType.GRASS_MIDDLE_VERTICAL || tile_type == TileType.GRASS_SURROUNDED:
		return true
	return false

func init_texture_map(map_size):
	var texture_map = []
	for i in range(map_size):
		texture_map.append([])
		for j in range(map_size):
			texture_map[i].append(-1)
	return texture_map
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
