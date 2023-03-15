extends KinematicBody

export var gravity = Vector3.DOWN * 9.8
export var speed = 10
export var rot_speed = 0.85

var velocity = Vector3.ZERO

var tree_detected = false
var chopping_tree = false
var log_detected = false
var chopping_log = false

# grappling hook
var grappling = false
# the location the grappling hook anchors to
var hooked_node = null
var hooked_parent = null
var send_out_hook = false
var get_hooked_node = false

onready var main_camera = $MainCamera
onready var grapplecast = $MainCamera/GrappleCast
onready var inventory = $Inventory

var grappling_hook:Resource
var grappling_hook_instance = null
var grappling_hook_speed = 0.25

var return_grapple_speed = 0.1325
var send_grapple_speed = 0.15

var root = null

# the grappling hook attached to the axe shaft bone
onready var axe_grappling_hook = $MainCamera/AxePick/Armature/Skeleton/UtilityAttachment/GrapplingHook

func _ready():
	root = get_tree().get_root()
	connect("grapple_signal", self, "_catch_grapple_signal")
	grappling_hook = load("res://Scenes/GrapplingHook.tscn")
	pass # Replace with function body.

func grapple(delta):
	if grappling:
		
		# 1st state, checked if raycast is intersecting a registered item
		if hooked_node == null:
			hooked_node = grapplecast.get_collider()
			if hooked_node != null and ("Fruit" in hooked_node.name or "Mushroom" in hooked_node.name):
				# TODO: send hook to raycast hit instead of the object in general
				send_out_hook = true
				hooked_parent = hooked_node.get_parent()
				var hooked_node_location = hooked_node.global_transform.origin
				
				# instantiate grappling hook
				grappling_hook_instance = grappling_hook.instance()
				grappling_hook_instance.global_translate(axe_grappling_hook.global_transform.origin)
				
				grappling_hook_instance.transform.basis = grappling_hook_instance.transform.basis.rotated(Vector3(1, 0, 0), main_camera.get_rotation().x)
				grappling_hook_instance.transform.basis = grappling_hook_instance.transform.basis.rotated(Vector3(0, 1, 0), self.transform.basis.get_euler().y)
				grappling_hook_instance.transform.basis = grappling_hook_instance.transform.basis.rotated(Vector3(0, 0, 1), main_camera.get_rotation().z)

				root.add_child(grappling_hook_instance)
			else: # end early if we don't know how to handle this item
				hooked_node = null
				grappling = false
		# 2nd state, make the hook travel to the hooked item
		elif send_out_hook:
			if grappling_hook_instance.global_transform.origin.distance_to(hooked_node.global_transform.origin) > 1:
				var hooked_node_direction = (hooked_node.global_transform.origin - grappling_hook_instance.global_transform.origin).normalized()
				grappling_hook_instance.transform.basis = grappling_hook_instance.transform.basis.rotated(hooked_node_direction, PI/8)
				grappling_hook_instance.global_transform.origin = lerp(grappling_hook_instance.global_transform.origin, hooked_node.global_transform.origin, send_grapple_speed)
			else:
				hooked_node.add_child(grappling_hook_instance)
				send_out_hook = false
				get_hooked_node = true
		# 3rd state, make the hook and hooked item travel to player
		elif get_hooked_node:
			if hooked_node.global_transform.origin.distance_to(global_transform.origin) > 1:
				grappling_hook_instance.global_transform.origin = lerp(hooked_node.global_transform.origin, global_transform.origin, return_grapple_speed)
				hooked_node.global_transform.origin = lerp(hooked_node.global_transform.origin, global_transform.origin, return_grapple_speed)
			else:
				grappling = false
				get_hooked_node = false
				var inventory_key = item_name_to_inventory_key(hooked_node.name)
				if inventory_key != "":
					inventory.add_item_to_inventory(inventory_key)
				root.remove_child(grappling_hook_instance)
				hooked_parent.remove_child(hooked_node)
				hooked_node = null
				hooked_parent = null
	pass

func item_name_to_inventory_key(item_name):
	var inventory_key = ""
	if "Nana" in item_name:
		inventory_key = inventory.NANA_FRUIT_KEY
	elif "Mushroom" in item_name:
		inventory_key = inventory.MUSHROOM_KEY
	return inventory_key

func _physics_process(delta):
	velocity += gravity * delta
	get_input(delta)
	if grappling:
		#var space_state = get_world_3d().direct_space_state
		grapple(delta)
	velocity = move_and_slide(velocity, Vector3.UP, true)

func get_input(delta):
	var vy = velocity.y
	velocity = Vector3.ZERO
	if Input.is_action_pressed("forward"):
		velocity += -transform.basis.z * speed
	if Input.is_action_pressed("back"):
		velocity += transform.basis.z * speed
	if Input.is_action_pressed("right"):
		velocity += transform.basis.x * speed
	if Input.is_action_pressed("left"):
		velocity += -transform.basis.x * speed
	velocity.y = vy
	
	#if Input.is_action_just_pressed("ability"):
	#	print("attempting to grapple")
	#	if grapplecast.is_colliding():
	#		if not grappling:
	#			print("grappling")
	#			grappling = true
	#
	# TODO: change active item based on order of inventory
	#if Input.is_action_just_pressed("change-item"):
	#	inventory.set_active_item(key)

func add_tree_to_chop(body):
	print("tree chop event received")
	tree_detected = true
	pass

func add_log_to_chop(body):
	print("log chop event received")
	log_detected = true
	pass

func _catch_grapple_signal():
	grappling = true
	pass
