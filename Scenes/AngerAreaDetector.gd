extends Area3D

@onready var signal_was_sent = false

signal is_pissed

func _ready():
	connect("body_entered",Callable(self,"callback"))
	pass

func callback(body):
	if body.name == "Player" && !signal_was_sent:
		var parent = get_parent()
		connect("is_pissed",Callable(parent,"_on_pissed"))
		emit_signal("is_pissed", parent)
		signal_was_sent = true
	pass
