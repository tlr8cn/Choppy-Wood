extends Spatial

onready var axe_collider = get_node("Armature/Skeleton/AxeTipAttachment/AxeTip/CollisionShape")
onready var pick_collider = get_node("Armature/Skeleton/PickTipAttachment/PickTip/CollisionShape")
onready var anim_tree = get_node("AnimationPlayer/AnimationTree")
onready var state_machine = anim_tree["parameters/playback"]

onready var player = get_tree().get_root().get_node("Spatial").get_node("Player")
onready var inventory = player.get_node("Inventory")

# TODO: this can be an enum (Options: AXE, SIDE, PICK)
var axe_pick_mode = "AXE"
var next_mode = "SIDE"
var chopping = false
var chop_timer = 0.0
var chop_cap = 1.0
var transitioning = false
var transition_cap = 1.0
var transition_timer = 0.0

var active_collider

signal grapple_signal

func _ready():
	connect("chop_end", self, "_on_chop_end")
	set_process_input(true)
	axe_collider.disabled = true
	pick_collider.disabled = true
	active_collider = axe_collider
	pass

func _process(delta):
	get_input()
	if chopping:
		chop_timer += delta
		if chop_timer >= chop_cap:
			print("ending chop by timer")
			chopping = false
			active_collider.disabled = true
	elif transitioning:
		transition_timer += delta
		if transition_timer >= transition_cap:
			if next_mode == "AXE":
				state_machine.travel("IdleAxe")
			elif next_mode == "SIDE":
				state_machine.travel("IdleSide")
				# only toggle colliders when switching from axe to pick (side is technically still axe)
			elif next_mode == "PICK":
				state_machine.travel("IdlePick")
			elif next_mode == "UTILITY":
				state_machine.travel("IdleUtility")
				
			axe_pick_mode = next_mode
			toggle_active_collider()
			transition_timer = 0.0
			transitioning = false
	pass

func toggle_active_collider():
	# TODO: no collider when utility
	if axe_pick_mode == "AXE" || axe_pick_mode == "SIDE":
		active_collider = axe_collider
	elif axe_pick_mode == "PICK":
		active_collider = pick_collider
	pass

func get_input():
	if Input.is_action_just_pressed("chop"):
		if axe_pick_mode == "AXE":
			state_machine.travel("AxeWindup")
		elif axe_pick_mode == "SIDE":
			state_machine.travel("SideWindup")
		elif axe_pick_mode == "PICK":
			state_machine.travel("PickWindup")
		elif axe_pick_mode == "UTILITY":
			state_machine.travel("UtilityAim")
	elif Input.is_action_just_released("chop"):
		active_collider.disabled = false
		chopping = true
		chop_timer = 0.0
		if axe_pick_mode == "AXE":
			state_machine.travel("AxeChop")
		elif axe_pick_mode == "SIDE":
			state_machine.travel("SideChop")
		elif axe_pick_mode == "PICK":
			state_machine.travel("PickChop")
		elif axe_pick_mode == "UTILITY":
			if !is_connected("grapple_signal", player, "_catch_grapple_signal"):
				connect("grapple_signal", player, "_catch_grapple_signal")
			emit_signal("grapple_signal")
			state_machine.travel("UtilityShoot")
	elif Input.is_action_pressed("stance"):
		if axe_pick_mode == "AXE":
			state_machine.travel("AxeToSideTransition")
			transitioning = true
			next_mode = "SIDE"
		elif axe_pick_mode == "SIDE":
			state_machine.travel("SideToPickTransition")
			transitioning = true
			next_mode = "PICK"
		elif axe_pick_mode == "PICK":
			transitioning = true
			next_mode = "UTILITY"
			state_machine.travel("PickToUtilityTransition")
		elif axe_pick_mode == "UTILITY":
			transitioning = true
			next_mode = "AXE"
			state_machine.travel("UtilityToAxeTransition")
	elif Input.is_action_just_pressed("throw"):
		inventory.throw_active_item()

func chop_end():
	active_collider.disabled = true
	pass
