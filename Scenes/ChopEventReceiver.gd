extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var child_log:Resource

var log_rotation_offset1:float
var log_rotation_offset2:float

var half_log_rotation_offset1 = PI
var half_log_rotation_offset2 = 0

var quarter_log_rotation_offset1 = 0
var quarter_log_rotation_offset2 = -PI/2

var initial_torque = 250
onready var do_apply_inital_torque = true

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_meta("type", "log")
	
	if "Quarter Log" in name:
		child_log = load("res://Scenes/Small Log.tscn")
		log_rotation_offset1 = quarter_log_rotation_offset1
		log_rotation_offset2 = quarter_log_rotation_offset2
	elif "Half Log" in name:
		child_log = load("res://Scenes/Quarter Log.tscn")
		log_rotation_offset1 = quarter_log_rotation_offset1
		log_rotation_offset2 = quarter_log_rotation_offset2
	elif "Log" in name:
		child_log = load("res://Scenes/Half Log.tscn")
		log_rotation_offset1 = half_log_rotation_offset1
		log_rotation_offset2 = half_log_rotation_offset2
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if do_apply_inital_torque:
		# TODO (BUG): not working as well for a small log
		if ("Quarter Log" in name or "Small Log" in name) and get_meta("orientation") == "right":
			apply_impulse(Vector3(0,  0.375, 0), Vector3(initial_torque*transform.basis.z.x, initial_torque*transform.basis.z.y, initial_torque*transform.basis.z.z))
		else:
			apply_impulse(Vector3(0, 0.375, 0), Vector3(-initial_torque*transform.basis.x.x, -initial_torque*transform.basis.x.y, -initial_torque*transform.basis.x.z))
		do_apply_inital_torque = false
	pass

func _on_chop(body, split_dir):
	if "Small Log" in name:
		return

	if "Half Log" in name or "Quarter Log" in name:
		# TODO: basis should maintain the y rotation of the body.transform
		split_dir = Basis(Vector3(0, 1, 0), body.transform.basis.get_euler().y)
	
	if self == body:
		var instance1 = child_log.instance()
		instance1.set_meta("orientation", "left")
		var pos1 = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z)
		instance1.global_translate(pos1)
		instance1.transform.basis = instance1.transform.basis.rotated(Vector3(0, 1, 0), split_dir.get_euler().y + log_rotation_offset1)
		get_tree().get_root().add_child(instance1)
		
		var instance2 = child_log.instance()
		instance1.set_meta("orientation", "right")
		var pos2 = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z)
		instance2.global_translate(pos2)
		# rotate around y axis
		instance2.transform.basis = instance2.transform.basis.rotated(Vector3(0, 1, 0), split_dir.get_euler().y + log_rotation_offset2)
		get_tree().get_root().add_child(instance2)
		
		queue_free()
	return

#func _integrate_forces(state):
#	if do_apply_inital_torque:
#		applied_torque = initial_torque
