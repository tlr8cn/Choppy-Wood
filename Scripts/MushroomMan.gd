extends KinematicBody


export var gravity = Vector3.DOWN * 9.8
onready var speed = 1.85
export var rot_speed = 0.85

var velocity = Vector3.ZERO
var falling_velocity = Vector3.ZERO

onready var anim_tree = get_node("AnimationTree")
onready var collider = get_node("CollisionShape")
onready var player = get_node("/root/Spatial/Player")

var is_pissed = false

var state_machine

var mushroom_half:Resource

var rotation_offset1 = PI
var rotation_offset2 = 0

onready var do_apply_initial_torque

# Called when the node enters the scene tree for the first time.
func _ready():
	mushroom_half = load("res://Scenes/MushroomManHalf.tscn")
	
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

func _on_chop(body, split_dir):
	split_dir = Basis(Vector3(0, 1, 0), body.transform.basis.get_euler().y)
	if self == body:
		var instance1 = mushroom_half.instance()
		instance1.set_meta("orientation", "left")
		var pos1 = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z)
		instance1.global_translate(pos1)
		instance1.transform.basis = instance1.transform.basis.rotated(Vector3(0, 1, 0), split_dir.get_euler().y + rotation_offset1)
		get_tree().get_root().add_child(instance1)
		# TODO: attach a script to the halves to apply initial impulse
		
		var instance2 = mushroom_half.instance()
		instance1.set_meta("orientation", "right")
		var pos2 = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z)
		instance2.global_translate(pos2)
		# rotate around y axis
		instance2.transform.basis = instance2.transform.basis.rotated(Vector3(0, 1, 0), split_dir.get_euler().y + rotation_offset2)
		get_tree().get_root().add_child(instance2)
		
		queue_free()
