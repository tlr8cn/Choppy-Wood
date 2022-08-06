extends KinematicBody

export var gravity = Vector3.DOWN * 9.8
export var speed = 10
export var rot_speed = 0.85

var velocity = Vector3.ZERO
var maul_offset = 0.2

onready var anim_player =  get_node("/root/Spatial/AnimationPlayer")
onready var splitting_maul = get_node("/root/Spatial/Player/MainCamera/SplittingMaul")
var original_maul_position = Vector3()
# Called when the node enters the scene tree for the first time.

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
		anim_player.queue("maul_windup")
	if Input.is_action_just_released("chop"):
		anim_player.queue("maul_chop")
		splitting_maul.get_node("RigidBody").get_node("CollisionShape").disabled = false
		# TODO deactivate collider when animation finishes or when collision occurs
		# TODO checking when animation finishes might require sending a signal from the maul script
		# to be handled here
		#splitting_maul.transform.origin.x = original_maul_position.x

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
