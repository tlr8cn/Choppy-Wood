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
var send_out_hook = false
var get_hooked_node = false

onready var grapplecast = $MainCamera/GrappleCast
var grappling_hook:Resource
var grappling_hook_instance = null

# the grappling hook attached to the axe shaft bone
onready var axe_grappling_hook = $MainCamera/AxePick/Armature/Skeleton/UtilityAttachment/GrapplingHook

func _ready():
	connect("grapple_signal", self, "_catch_grapple_signal")
	grappling_hook = load("res://Scenes/GrapplingHook.tscn")
	pass # Replace with function body.

func grapple():
	if grappling:
		#velocity.y = 0

		# 1st state, checked if raycast is intersecting a registered item
		if hooked_node == null:
			hooked_node = grapplecast.get_collider()
			if hooked_node != null and ("Fruit" in hooked_node.name or "Mushroom" in hooked_node.name):
				print("getting fruit")
				print(hooked_node.name)
				var root = get_tree().get_root()
				send_out_hook = true
				var hooked_parent = hooked_node.get_parent()
				var hooked_node_location = hooked_node.transform.origin
				hooked_parent.remove_child(hooked_node)
				root.add_child(hooked_node)
				
				# instantiate grappling hook
				grappling_hook_instance = grappling_hook.instance()
				grappling_hook_instance.global_translate(axe_grappling_hook.transform.origin)
				#grappling_hook_instance.transform.basis = axe_grappling_hook.transform.basis
				root.add_child(grappling_hook_instance)
			else: # end early if we don't know how to handle this item
				hooked_node = null
				grappling = false
		# 2nd state, make the hook travel to the hooked item
		elif send_out_hook:
			# TODO: lerp manually
			if grappling_hook_instance.transform.origin.distance_to(hooked_node.transform.origin) > 0.75:
				grappling_hook_instance.transform.origin = lerp(hooked_node.transform.origin, grappling_hook_instance.transform.origin, 0.75)
			else:
				grappling_hook_instance.transform.origin = hooked_node.transform.origin
				get_tree().get_root().remove_child(grappling_hook_instance)
				hooked_node.add_child(grappling_hook_instance)
				send_out_hook = false
				get_hooked_node = true
		# 3rd state, make the hook and hooked item travel to player
		elif get_hooked_node:
			if hooked_node.transform.origin.distance_to(transform.origin) > 0.75:
				hooked_node.transform.origin = lerp(transform.origin, hooked_node.transform.origin, 0.75)
			else:
				grappling = false
				get_hooked_node = false
				# TODO: add hooked item to inventory
				hooked_node.remove_child(grappling_hook_instance)
				hooked_node = null
				# TODO: add fruit to inventory
	#if bonker.is_colliding():
	#	grappling = false
	#	hooked_node = null
	#	hookpoint_get = false
	#	global_translate(Vector3(0, -1, 0))

func _physics_process(delta):
	velocity += gravity * delta
	get_input(delta)
	if grappling:
		#var space_state = get_world_3d().direct_space_state
		grapple()
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
	print("caught grapple signal")
	grappling = true
	pass
