extends Area

class_name TerrainNode

signal player_entered

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var plane_width
var plane_depth
var plane_divider
var plane_subdivision_width

var mdt

var was_generated = false

# TODO: I think, in addition to the mdt, we need a list of vertices that we can use to access this node
# TODO: move the CollisionShape to the bottom corner vertex
func _init(mdt, mdt_vertices, plane_width, plane_depth, plane_divider):
	self.mdt = mdt
	self.mdt_vertices = mdt_vertices
	self.plane_width = plane_width
	self.plane_depth = plane_depth
	self.plane_divider = plane_divider
	self.plane_subdivision_width = self.plane_width/self.plane_divider

	var collision_shape = SphereShape.new()
	collision_shape.set_radius(2.0)
	
	var collision = CollisionShape.new()
	collision.set_shape(collision_shape)
	
	add_child(collision)
	
	connect("body_entered", self, "callback")

func callback(body):
	var body_name = body.get_name()
	print("body entered " + body_name)
	if body_name == "Player" && !was_generated:
		generate_terrain()
		was_generated = true

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func generate_terrain():
	# TODO: implement
	# mdt is a flat array of vertices; in order to access, we need to convert x and z to
	# i in the mdt plane
	for x in range mdt.
	var i_array = get_i_bounds_from_x_z()
	var i_min = i_array[0]
	var i_max = i_array[1]
	#for i in range(i_min, i_max)
	pass


func get_i_bounds_from_x_z():
	
	pass
