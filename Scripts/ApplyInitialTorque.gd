extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var initial_torque:float
onready var do_apply_inital_torque = true
var torque_timer = 0.0
onready var run_torque_timer = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if do_apply_inital_torque:
		# TODO (BUG): not working as well for a small log
#		if ("Quarter Log" in name or "Small Log" in name) and get_meta("orientation") == "right":
#			apply_impulse(Vector3(0,  0.375, 0), Vector3(initial_torque*transform.basis.z.x, initial_torque*transform.basis.z.y, initial_torque*transform.basis.z.z))
#		elif "Half Log" in name:
		apply_impulse(Vector3(0, 0.375, 0), Vector3(-initial_torque*transform.basis.x.x, -initial_torque*transform.basis.x.y, -initial_torque*transform.basis.x.z))
		do_apply_inital_torque = false
		torque_timer = 0.0
		run_torque_timer = true
	elif run_torque_timer:
		torque_timer += delta
		if torque_timer > 0.5:
			self.axis_lock_angular_x = true
			self.axis_lock_angular_y = true
			self.axis_lock_angular_z = true
			run_torque_timer = false
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
