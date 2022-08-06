extends CollisionShape


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


# @params
# Object camera
# InputEvent event
# Vector3 click_position
# Vector3 click_normal
# int shape_idx
# TODO: not working - when is _input_event even called?
func _input_event (camera, event, click_position, click_normal, shape_idx):
	print("hi")
	if event.is_action_just_pressed("grab"):
		print("grabbed " + name)
