extends RigidBody3D

const BIG_LOG_LENGTH = 5.5

var child_log:Resource

func _ready():
	self.set_meta("type", "log")
	
	if "BigLog" in name:
		child_log = load("res://Scenes/Log.tscn")
		#log_rotation_offset1 = quarter_log_rotation_offset1
		#log_rotation_offset2 = quarter_log_rotation_offset2
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_chop(body, split_dir):
	if self == body:
		var z_pos = -BIG_LOG_LENGTH/3 - BIG_LOG_LENGTH/6
		var z_inc = BIG_LOG_LENGTH/6
		for i in 6:
			var instance = child_log.instantiate()
			var pos = Vector3(self.transform.origin.x, self.transform.origin.y + 0.35, self.transform.origin.z + z_pos)
			instance.global_translate(pos)
			instance.transform.basis = instance.transform.basis.rotated(Vector3(1, 0, 0), PI/2)
			instance.axis_lock_angular_x = true
			instance.axis_lock_angular_z = true
			get_tree().get_root().add_child(instance)
			z_pos = z_pos + z_inc
		
		#var instance2 = child_log.instantiate()
		#var pos2 = Vector3(self.transform.origin.x, self.transform.origin.y, self.transform.origin.z)
		#instance2.global_translate(pos2)
		# rotate around y axis
		#instance2.transform.basis = instance2.transform.basis.rotated(Vector3(0, 1, 0), split_dir.get_euler().y + log_rotation_offset2)
		#get_tree().get_root().add_child(instance2)
		
		queue_free()
	return
