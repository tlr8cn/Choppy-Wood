extends Spatial

var instance_y_offset = 0.85

var area_width = 85
var area_height = 75
var separation = 0.75

var rng = RandomNumberGenerator.new()

var tuft_options = Array()

func _ready():
	var grass_tuft_small = get_node("GrassTuftSmall")
	var grass_tuft_large = get_node("GrassTuftLarge")
	tuft_options.append(grass_tuft_small)
	tuft_options.append(grass_tuft_large)
	
	var start_x = transform.origin.x - separation*(area_width/2)
	var start_z = transform.origin.z - separation*(area_height/2)
	
	var current_x = start_x - separation
	var current_z = start_z - separation
	
	for i in area_width:
		current_x += separation
		current_z = start_z - separation
		for j in area_height:
			current_z += separation
			
			# Random chance that we don't instantiate
			var roll = rng.randi_range(0, 100)
			if roll > 56:
				continue
			
			# Random instance
			var index = rng.randi_range(0, 1)
			var instance = tuft_options[index].duplicate()
			
			# Random, minor offsets in the x and z directions
			var minor_offset_x = rng.randf_range(-separation/2.0, separation/2.0)
			var minor_offset_z = rng.randf_range(-separation/2.0, separation/2.0)
			var pos = Vector3(current_x + minor_offset_x, transform.origin.y + instance_y_offset, current_z + minor_offset_z)
			instance.global_translate(pos)
			var random_rotation = rng.randf_range(0, 2*PI)
			instance.transform.basis = instance.transform.basis.rotated(Vector3(0, 1, 0), transform.basis.get_euler().y + random_rotation)
			instance.scale = Vector3(0.35, 0.35, 0.35)
			instance.visible = true
			add_child(instance)
	pass

