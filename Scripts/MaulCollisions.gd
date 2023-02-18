extends RigidBody3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@onready var player = get_tree().get_root().get_node("Node3D").get_node("Player")
# signal to be emitted to logs
# TODO: might also need to send unique ID of node
signal was_chopped

func _ready():
	connect("body_entered",Callable(self,"callback"))
	pass

func callback(body):
	var body_name = body.get_name()
	# DEBUG
	# print("hit " + body_name)
	if body_name == "Player" || body_name == "Ground":
		return
	
	if body_name != "Tree":
		connect_and_send_chopped_signal(body)
	else:
		var tree_generator = body.get_parent()
		connect_and_send_chopped_signal(tree_generator)
	
	get_node("CollisionShape3D").disabled = true

func connect_and_send_chopped_signal(node):
	if !is_connected("was_chopped",Callable(node,"_on_chop")):
		connect("was_chopped",Callable(node,"_on_chop"))
	emit_signal("was_chopped", node, player.get_transform().basis)
	pass
