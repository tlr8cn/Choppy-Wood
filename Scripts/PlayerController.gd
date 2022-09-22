extends KinematicBody

export var gravity = Vector3.DOWN * 9.8
export var speed = 10
export var rot_speed = 0.85

var velocity = Vector3.ZERO
var maul_offset = 0.2

onready var anim_player =  get_node("/root/Spatial/AnimationPlayer")
onready var anim_tree =  get_node("/root/Spatial/AnimationTree")
onready var splitting_maul = get_node("/root/Spatial/Player/MainCamera/SplittingMaul")
var original_maul_position = Vector3()
# Called when the node enters the scene tree for the first time.

var tree_detected = false
var chopping_tree = false
var log_detected = false
var chopping_log = false

func _ready():
	original_maul_position = splitting_maul.transform.origin
	pass # Replace with function body.

func _physics_process(delta):
	velocity += gravity * delta
	get_input(delta)
	velocity = move_and_slide(velocity, Vector3.UP, true)

# TODO: process input for standing logs upright
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
	
	if Input.is_action_just_pressed("chop"):
		if tree_detected:
			anim_player.queue("maul_windup_side")
			tree_detected = false
			chopping_tree = true
		else:
			anim_player.queue("maul_windup")
			log_detected = false
			chopping_log = true
	if Input.is_action_just_released("chop"):
		if chopping_log:
			anim_player.queue("maul_chop")
			chopping_log = false
		elif chopping_tree:
			anim_player.queue("maul_chop_side")
			chopping_tree = false
			
		splitting_maul.get_node("RigidBody").get_node("CollisionShape").disabled = false
		# TODO deactivate collider when animation finishes or when collision occurs
		# TODO checking when animation finishes might require sending a signal from the maul script
		# to be handled here
		#splitting_maul.transform.origin.x = original_maul_position.x

func add_tree_to_chop(body):
	print("tree chop event received")
	tree_detected = true
	pass

func add_log_to_chop(body):
	print("log chop event received")
	log_detected = true
	pass

#func _on_tree_detected():
#	tree_detected = true
#	print("tree about to be chopped")
#	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
