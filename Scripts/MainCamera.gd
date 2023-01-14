extends Camera

onready var Yaw = get_parent()
onready var do_ray_cast = false

const ray_length = 1000

var cast_event:InputEvent

onready var player = get_parent()
onready var inventory = player.get_node("Inventory")
#signal tree_detected

func _ready():
	#connect("tree_detected", player, "_on_tree_detected")
	## Tell Godot that we want to handle input
	set_process_input(true)

func look_updown_rotation(rotation = 0):
	"""
	Get the new rotation for looking up and down
	"""
	var toReturn = self.get_rotation() + Vector3(rotation, 0, 0)

	##
	## We don't want the player to be able to bend over backwards
	## neither to be able to look under their arse.
	## Here we'll clamp the vertical look to 90° up and down
	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)

	return toReturn

func look_leftright_rotation(rotation = 0):
	"""
	Get the new rotation for looking left and right
	"""
	return Yaw.get_rotation() + Vector3(0, rotation, 0)

func mouse(event):
	"""
	First person camera controls
	"""
	##
	## We'll use the parent node "Yaw" to set our left-right rotation
	## This prevents us from adding the x-rotation to the y-rotation
	## which would result in a kind of flight-simulator camera
	Yaw.set_rotation(look_leftright_rotation(event.relative.x / -200))

	##
	## Now we can simply set our y-rotation for the camera, and let godot
	## handle the transformation of both together
	self.set_rotation(look_updown_rotation(event.relative.y / -200))

func _input(event):
	##
	## We'll only process mouse motion events
	if event is InputEventMouseMotion:
		return mouse(event)
	elif event is InputEventMouseButton and event.is_action_pressed("grab"):
		cast_event = event
		do_ray_cast = true
	elif event is InputEventMouseButton and event.is_action_pressed("chop"):
		cast_event = event
		do_ray_cast = true
	elif event is InputEventKey and event.is_action_pressed("throw"):
		inventory.throw_active_item()

func _enter_tree():
	"""
	Hide the mouse when we start
	"""
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _leave_tree():
	"""
	Show the mouse when we leave
	"""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if do_ray_cast:
		var space_state = get_world().direct_space_state
		var from = self.project_ray_origin(cast_event.position)
		var to = from + self.project_ray_normal(cast_event.position) * ray_length
		var intersection_map = space_state.intersect_ray(from, to)
		if intersection_map:
			#print("ray cast hit:")
			#print(intersection_map["collider"])
			if "Log" in intersection_map["collider"].name && !("Big" in intersection_map["collider"].name) && !("Small" in intersection_map["collider"].name):
				intersection_map["collider"].axis_lock_angular_x = false
				intersection_map["collider"].axis_lock_angular_y = false
				intersection_map["collider"].axis_lock_angular_z = false
				intersection_map["collider"].transform.basis = Basis()
				intersection_map["collider"].axis_lock_angular_x = true
				intersection_map["collider"].axis_lock_angular_y = true
				intersection_map["collider"].axis_lock_angular_z = true
				player.add_log_to_chop(intersection_map["collider"])
			elif "Big" in intersection_map["collider"].name:
				player.add_log_to_chop(intersection_map["collider"])
			elif "Small" in intersection_map["collider"].name:
				var item_added_successfully = inventory.add_item_to_inventory(inventory.FIREWOOD_KEY)
				if item_added_successfully:
					intersection_map["collider"].queue_free()
			elif "Tree" in intersection_map["collider"].name:
				print("chopping a tree")
				player.add_tree_to_chop(intersection_map["collider"])
				#emit_signal("tree_detected", player)
				
		do_ray_cast = false
