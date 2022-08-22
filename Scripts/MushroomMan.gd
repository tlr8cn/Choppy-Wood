extends KinematicBody


export var gravity = Vector3.DOWN * 9.8
export var speed = 1.85
export var rot_speed = 0.85

var velocity = Vector3.ZERO
var falling_velocity = Vector3.ZERO

onready var anim_tree = get_node("AnimationTree")
onready var collider = get_node("CollisionShape")
onready var player = get_node("/root/Spatial/Player")

var is_pissed = false

var state_machine

# Called when the node enters the scene tree for the first time.
func _ready():
	state_machine = anim_tree["parameters/playback"]
	state_machine.travel("Idle-loop")
	
	pass # Replace with function body.

func _physics_process(delta):
	### Initial State
	
	### Secondary State
	if is_pissed:
		look_at(player.transform.origin, Vector3.UP)
		var player_direction = (player.transform.origin - transform.origin).normalized()
		velocity = player_direction*speed + falling_velocity
		
		#velocity += player_direction*speed
		#velocity += gravity * delta
		velocity = move_and_slide(velocity, Vector3.UP, true)
		if get_slide_count() > 0:
			falling_velocity = Vector3.ZERO
		else: 
			falling_velocity += (gravity * delta)

func _on_pissed(body):
	print("mushie checking in")
	if !is_pissed:
		transform.origin = transform.origin + Vector3.UP*0.75
		state_machine.travel("Run-loop")
		get_node("CollisionShape").disabled = false
	is_pissed = true
