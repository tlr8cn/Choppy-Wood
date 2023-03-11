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
var get_hooked_node = false

onready var grapplecast = $MainCamera/GrappleCast

func grapple():
	if grappling:
		#velocity.y = 0
		if not get_hooked_node:
			hooked_node = grapplecast.get_collider()
			if "Fruit" in hooked_node.name:
				print("getting fruit")
				get_hooked_node = true
			else:
				print("hooked unknown node")
				print(hooked_node.name)
				grappling = false
		if hooked_node.transform.origin.distance_to(transform.origin) > 1:
			if get_hooked_node:
				hooked_node.transform.origin = lerp(transform.origin, hooked_node.transform.origin, 0.0005)
		else:
			grappling = false
			get_hooked_node = false
			# TODO: add fruit to inventory
	#if bonker.is_colliding():
	#	grappling = false
	#	hooked_node = null
	#	hookpoint_get = false
	#	global_translate(Vector3(0, -1, 0))

func _ready():
	pass # Replace with function body.

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
	
	if Input.is_action_just_pressed("ability"):
		if grapplecast.is_colliding():
			if not grappling:
				print("grappling")
				grappling = true
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
