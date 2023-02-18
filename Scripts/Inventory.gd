extends Node3D

class_name Inventory

const FIREWOOD_KEY = 'FIREWOOD'

var max_stack_size = 3

var inventory = {
	FIREWOOD_KEY: 0
}

var item_instance_ref = {}
var active_item = ''

# Called when the node enters the scene tree for the first time.
func _ready():
	var firewood_instance_ref = load("res://Scenes/Small log.tscn")
	register_item(FIREWOOD_KEY, firewood_instance_ref)
	pass # Replace with function body.

func register_item(key, instance_ref):
	if !item_instance_ref.has(key):
		item_instance_ref[key] = instance_ref
	pass

func add_item_to_inventory(key):
	if inventory.has(key) && inventory[key] < max_stack_size:
		inventory[key] += 1
		if active_item == '':
			active_item = key
		return true
	return false

func throw_active_item():
	if active_item == '' || inventory[active_item] == 0:
		print("no active item")
		pass
	print("throwing " + active_item)
	remove_item_from_inventory(active_item)

func remove_item_from_inventory(key):
	if inventory.has(key):
		if inventory[key] < 0:
			return false
		else:
			inventory[key] -= 1
			if item_instance_ref.has(key):
				var player = get_parent()
				print("instantiating " + key)
				var instance_ref = item_instance_ref[key]
				var item_instance = instance_ref.instantiate()
				var pos = Vector3(player.transform.origin.x, player.transform.origin.y + 2.0, player.transform.origin.z)
				item_instance.global_translate(pos)
				get_tree().get_root().add_child(item_instance)
				item_instance.apply_central_impulse(Vector3(-250*player.transform.basis.z.x, -250*player.transform.basis.z.y, -250*player.transform.basis.z.z))
			return true
	print("unknown inventory key: " + key)
	return false

func increase_max_stack_size():
	max_stack_size += 1
	pass
	
