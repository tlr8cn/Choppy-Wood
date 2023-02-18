extends RigidBody3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# []Resource: 0 = left; 1 = right
var child_log:Resource

var log_rotation_offset1:float
var log_rotation_offset2:float

var initial_torque = 250
@onready var do_apply_inital_torque = true
var torque_timer = 0.0
@onready var run_torque_timer = false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_meta("type", "log")
	
	if "Quarter Log" in name:
		child_log = load("res://Scenes/Small Log.tscn")
		log_rotation_offset1 = -PI/2
		log_rotation_offset2 = 0
	elif "Half Log" in name:
		child_log = load("res://Scenes/Quarter Log.tscn")
		log_rotation_offset1 = -PI/2
		log_rotation_offset2 = 0
	elif "Log" in name:
		child_log = load("res://Scenes/Half Log.tscn")
		log_rotation_offset1 = PI
		log_rotation_offset2 = 0
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if do_apply_inital_torque:
		if "Half Log" in name:
			apply_impulse(-initial_torque*transform.basis.x, Vector3(0, 0.375, 0))
		elif "Quarter Log" in name:
			if get_meta("orientation") == "left":
				apply_impulse(-initial_torque*transform.basis.x, Vector3(0, 0.35, 0))
			elif get_meta("orientation") == "right":
				apply_impulse(initial_torque*transform.basis.z, Vector3(0, 0.35, 0))
		elif "Small Log" in name:
			if get_meta("orientation") == "left":
				apply_impulse(-initial_torque*transform.basis.x, Vector3(0, 0.325, 0))
			elif get_meta("orientation") == "right":
				apply_impulse(initial_torque*transform.basis.z, Vector3(0, 0.325, 0))
		do_apply_inital_torque = false
		torque_timer = 0.0
		run_torque_timer = true
	elif run_torque_timer:
		torque_timer += delta
		if torque_timer > 0.25:
			self.axis_lock_angular_x = true
			self.axis_lock_angular_y = true
			self.axis_lock_angular_z = true
			run_torque_timer = false
	pass

func _on_chop(body, split_dir):
	if "Small Log" in name:
		return
	
	if "Half Log" in name or "Quarter Log" in name:
		# TODO: basis should maintain the y rotation of the body.transform
		split_dir = Basis(Vector3(0, 1, 0), body.transform.basis.get_euler().y)
	
	if self == body:
		var left_instance = child_log.instantiate()
		left_instance.set_meta("orientation", "left")
		var pos1 = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z)
		left_instance.global_translate(pos1)
		left_instance.transform.basis = left_instance.transform.basis.rotated(Vector3(0, 1, 0), split_dir.get_euler().y + log_rotation_offset1)
		get_tree().get_root().add_child(left_instance)
		
		var right_instance = child_log.instantiate()
		right_instance.set_meta("orientation", "right")
		var pos2 = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z)
		right_instance.global_translate(pos2)
		# rotate around y axis
		right_instance.transform.basis = right_instance.transform.basis.rotated(Vector3(0, 1, 0), split_dir.get_euler().y + log_rotation_offset2)
		get_tree().get_root().add_child(right_instance)
		
		queue_free()
	return

#func _integrate_forces(state):
#	if do_apply_inital_torque:
#		applied_torque = initial_torque
