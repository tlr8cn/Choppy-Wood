extends Area

onready var player = get_tree().get_root().get_node("Spatial").get_node("Player")
onready var axe_pick = get_tree().get_root().get_node("Spatial").get_node("Player").get_node("MainCamera").get_node("AxePick")

var side = ""

signal was_chopped
signal chop_end

func _ready():
	connect("body_entered", self, "_on_body_entered")
	
	if "AxeTip" in name:
		side = "AXE"
	elif "PickTip" in name:
		side = "PICK"
	
	pass

func _on_body_entered(body:Node):
	var body_name = body.get_name()
	
	# DEBUG
	print("hit " + body_name)
	
	# do nothing if we hit irrelevant objects
	if body_name == "Player" || body_name == "Ground":
		return
		
	if side == "AXE":
		if "Log" in body_name:
			connect_and_send_chopped_signal(body)
		elif "Tree" in body_name:
			var tree_generator = body.get_parent()
			connect_and_send_chopped_signal(tree_generator)
	# TODO: pick rocks
	#elif side == "PICK":
	#	if "Rock" in body_name:
	pass


func connect_and_send_chopped_signal(node):
	if !is_connected("was_chopped", node, "_on_chop"):
		connect("was_chopped", node, "_on_chop")
	# TODO: this would work better as a signal, but I couldn't get it to work
	axe_pick.chop_end()
	emit_signal("was_chopped", node, player.get_transform().basis)
	pass
