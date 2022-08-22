extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var player = get_tree().get_root().get_node("Spatial").get_node("Player")
# signal to be emitted to logs
# TODO: might also need to send unique ID of node
signal was_chopped

func _ready():
	connect("body_entered", self, "callback")
	pass

func callback(body):
	var body_name = body.get_name()
	print("hit " + body_name)
	if body_name == "Player" || body_name == "Ground":
		return
	#if body.get_meta("type") == "log":
	if !is_connected("was_chopped", body, "_on_chop"):
		connect("was_chopped", body, "_on_chop")
	emit_signal("was_chopped", body, player.get_transform().basis)
	get_node("CollisionShape").disabled = true
