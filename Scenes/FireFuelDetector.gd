extends Area3D

@onready var fire_simulation = get_parent().get_node("Fire")

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered",Callable(self,"callback"))
	pass

func callback(body):
	if "Small Log" in body.name:
		print("adding 3 fuel to fire")
		fire_simulation.add_fuel(3)
		body.queue_free()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
