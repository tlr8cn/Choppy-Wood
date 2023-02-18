extends Node

class_name Vertex

var coord = Vector3()
var uv = Vector2()
var normal = Vector3() 
var angle = 0.0 
var centerPoint = Vector3()

func _init(coord=Vector3(),normal=Vector3(),angle=0.0,centerPoint=Vector3()):
	self.coord = coord
	self.normal = normal
	self.angle = angle
	self.centerPoint = centerPoint

func set_uv(uv):
	self.uv = uv

func get_uv():
	return self.uv

func get_coord():
	return self.coord

func get_normal():
	return self.normal

func get_angle():
	return self.angle

func set_centerPoint(centerPoint):
	self.centerPoint = centerPoint

func get_centerPoint():
	return self.centerPoint








# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
