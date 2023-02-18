extends GPUParticles3D

class_name FireSimulation

var fuel_max = 9
var fuel_amount = 9
var fuel_level = 0

var level_by_amount = [0, 1, 1, 2, 2, 2, 3, 3, 4]
var decrease_timer = 15.0 # in seconds
var decrease_counter = 0.0

@onready var fire_sim:ParticleProcessMaterial = self.process_material
@onready var smoke:GPUParticles3D = get_node("Smoke")
@onready var smoke_sim:ParticleProcessMaterial = smoke.process_material
@onready var sparks:GPUParticles3D = get_node("Sparks")
@onready var sparks_sim:ParticleProcessMaterial = sparks.process_material

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	self.decrease_counter += delta
	if decrease_counter >= decrease_timer:
		remove_fuel()
		update_fuel_level()
		self.decrease_counter = 0.0
	pass

func remove_fuel():
	if fuel_amount > 1:
		self.fuel_amount -= 1
		print("campfire fuel amount decreased to ", fuel_amount)
	else:
		print("campfire is out of fuel")
	pass

func add_fuel(amount):
	if fuel_amount < fuel_max:
		if fuel_amount + amount >= fuel_max:
			self.fuel_amount = fuel_max
		else:
			self.fuel_amount += amount
	update_fuel_level()
	pass

func update_fuel_level():
	var initial_fuel_level = fuel_level
	self.fuel_level = level_by_amount[fuel_amount - 1]
	if initial_fuel_level > fuel_level:
		adjust_fire_simulation()
		print("campfire level decreased to ", fuel_level)
	elif initial_fuel_level < fuel_level:
		adjust_fire_simulation()
		print("campfire level increased to ", fuel_level)
		reset_counter()
	pass

func reset_counter():
	print("fuel added... timer reset")
	self.decrease_counter = 0.0
	pass

func adjust_fire_simulation():
	if fuel_level == 4:
		print("max flame")
		set_fire_sim_fuel_level_4()
		set_smoke_sim_fuel_level_4()
		set_sparks_sim_fuel_level_4()
	elif fuel_level == 3:
		print("moderate flame")
		set_fire_sim_fuel_level_3()
		set_smoke_sim_fuel_level_3()
		set_sparks_sim_fuel_level_3()
	elif fuel_level == 2:
		print("small flame")
		set_fire_sim_fuel_level_2()
		set_smoke_sim_fuel_level_2()
		set_sparks_sim_fuel_level_2()
	elif fuel_level == 1:
		set_fire_sim_fuel_level_1()
		set_smoke_sim_fuel_level_1()
		set_sparks_sim_fuel_level_1()
		print("embers")
	pass

func set_fire_sim_fuel_level_4():
	self.amount = 200
	self.lifetime = 0.5
	fire_sim.scale = 0.8
	fire_sim.scale_random = 0.0
	fire_sim.damping = 0.0
	fire_sim.damping_random = 0.0
	fire_sim.trail_divisor = 7
	fire_sim.emission_sphere_radius = 0.4
	fire_sim.initial_velocity = 5.0
	fire_sim.initial_velocity_random = 0.1
	fire_sim.angular_velocity = 40.0
	fire_sim.angular_velocity_random = 1.0
	fire_sim.linear_accel = 4.0
	fire_sim.linear_accel_random = 1.0
	pass

func set_smoke_sim_fuel_level_4():
	smoke.transform.origin = Vector3(smoke.transform.origin.x, 1.3, smoke.transform.origin.z)
	smoke.amount = 50
	smoke.lifetime = 1.5
	smoke_sim.scale = 2.0
	smoke_sim.scale_random = 1.0
	smoke_sim.damping = 0.0
	smoke_sim.damping_random = 0.0
	smoke_sim.trail_divisor = 1
	smoke_sim.emission_sphere_radius = 0.3
	smoke_sim.initial_velocity = 1.0
	smoke_sim.initial_velocity_random = 0.5
	smoke_sim.angular_velocity = 40.0
	smoke_sim.angular_velocity_random = 1.0
	smoke_sim.linear_accel = 2.0
	smoke_sim.linear_accel_random = 1.0
	pass

func set_sparks_sim_fuel_level_4():
	sparks.transform.origin = Vector3(sparks.transform.origin.x, 1.475, sparks.transform.origin.z)
	sparks.emitting = true
	sparks.amount = 80
	sparks.lifetime = 0.5
	sparks_sim.scale = 0.1
	sparks_sim.scale_random = 0.3
	sparks_sim.damping = 2.0
	sparks_sim.damping_random = 1.0
	sparks_sim.trail_divisor = 5
	sparks_sim.emission_sphere_radius = 0.6
	sparks_sim.initial_velocity = 2.0
	sparks_sim.initial_velocity_random = 1.0
	sparks_sim.angular_velocity = 0.0
	sparks_sim.angular_velocity_random = 0.0
	sparks_sim.linear_accel = 5.0
	sparks_sim.linear_accel_random = 1.0
	pass

func set_fire_sim_fuel_level_3():
	self.amount = 175 #
	self.lifetime = 0.4 #
	fire_sim.scale = 0.6 #
	fire_sim.scale_random = 0.0
	fire_sim.damping = 0.0
	fire_sim.damping_random = 0.0
	fire_sim.trail_divisor = 10 #
	fire_sim.emission_sphere_radius = 0.3 #
	fire_sim.initial_velocity = 3.5 #
	fire_sim.initial_velocity_random = 0.1
	fire_sim.angular_velocity = 30.0 #
	fire_sim.angular_velocity_random = 1.0
	fire_sim.linear_accel = 3.5 #
	fire_sim.linear_accel_random = 1.0
	pass

func set_smoke_sim_fuel_level_3():
	smoke.transform.origin = Vector3(smoke.transform.origin.x, 1.382, smoke.transform.origin.z)
	smoke.amount = 40 #
	smoke.lifetime = 1.0 #
	smoke_sim.scale = 1.0 #
	smoke_sim.scale_random = 1.0
	smoke_sim.damping = 0.0
	smoke_sim.damping_random = 0.0
	smoke_sim.trail_divisor = 3 #
	smoke_sim.emission_sphere_radius = 0.2 #
	smoke_sim.initial_velocity = 0.5 #
	smoke_sim.initial_velocity_random = 0.5
	smoke_sim.angular_velocity = 30.0 #
	smoke_sim.angular_velocity_random = 1.0
	smoke_sim.linear_accel = 1.75 #
	smoke_sim.linear_accel_random = 1.0
	pass
	
func set_sparks_sim_fuel_level_3():
	sparks.transform.origin = Vector3(sparks.transform.origin.x, 1.4, sparks.transform.origin.z)
	sparks.emitting = true
	sparks.amount = 25 #
	sparks.lifetime = 0.35 #
	sparks_sim.scale = 0.075 #
	sparks_sim.scale_random = 0.3
	sparks_sim.damping = 2.25 #
	sparks_sim.damping_random = 1.0
	sparks_sim.trail_divisor = 5
	sparks_sim.emission_sphere_radius = 0.4 #
	sparks_sim.initial_velocity = 1.75 #
	sparks_sim.initial_velocity_random = 1.0
	sparks_sim.angular_velocity = 0.0
	sparks_sim.angular_velocity_random = 0.0
	sparks_sim.linear_accel = 4.0 #
	sparks_sim.linear_accel_random = 1.0
	pass

func set_fire_sim_fuel_level_2():
	self.amount = 125 #
	self.lifetime = 0.35 #
	fire_sim.scale = 0.4 #
	fire_sim.scale_random = 0.0
	fire_sim.damping = 0.0
	fire_sim.damping_random = 0.0
	fire_sim.trail_divisor = 10 #
	fire_sim.emission_sphere_radius = 0.2 #
	fire_sim.initial_velocity = 3.0 #
	fire_sim.initial_velocity_random = 0.1
	fire_sim.angular_velocity = 30.0 
	fire_sim.angular_velocity_random = 1.0
	fire_sim.linear_accel = 3.0 
	fire_sim.linear_accel_random = 1.0
	pass

func set_smoke_sim_fuel_level_2():
	smoke.transform.origin = Vector3(smoke.transform.origin.x, 1.0, smoke.transform.origin.z)
	smoke.amount = 30 #
	smoke.lifetime = 0.8 #
	smoke_sim.scale = 0.75 #
	smoke_sim.scale_random = 1.0
	smoke_sim.damping = 0.0
	smoke_sim.damping_random = 0.0
	smoke_sim.trail_divisor = 4 #
	smoke_sim.emission_sphere_radius = 0.175 #
	smoke_sim.initial_velocity = 0.45 #
	smoke_sim.initial_velocity_random = 0.5
	smoke_sim.angular_velocity = 30.0 
	smoke_sim.angular_velocity_random = 1.0
	smoke_sim.linear_accel = 1.65 #
	smoke_sim.linear_accel_random = 1.0
	pass
	
func set_sparks_sim_fuel_level_2():
	sparks.emitting = false #
	pass

func set_fire_sim_fuel_level_1():
	self.amount = 50 #
	self.lifetime = 0.3 #
	fire_sim.scale = 0.2 #
	fire_sim.scale_random = 0.0
	fire_sim.damping = 0.0
	fire_sim.damping_random = 0.0
	fire_sim.trail_divisor = 10
	fire_sim.emission_sphere_radius = 0.25 #
	fire_sim.initial_velocity = 3.0 #
	fire_sim.initial_velocity_random = 0.1
	fire_sim.angular_velocity = 30.0 
	fire_sim.angular_velocity_random = 1.0
	fire_sim.linear_accel = 2.75 #
	fire_sim.linear_accel_random = 1.0
	pass

func set_smoke_sim_fuel_level_1():
	smoke.transform.origin = Vector3(smoke.transform.origin.x, 0.5, smoke.transform.origin.z)
	smoke.amount = 20 #
	smoke.lifetime = 0.6 #
	smoke_sim.scale = 0.6 #
	smoke_sim.scale_random = 1.0
	smoke_sim.damping = 0.0
	smoke_sim.damping_random = 0.0
	smoke_sim.trail_divisor = 4
	smoke_sim.emission_sphere_radius = 0.175 #
	smoke_sim.initial_velocity = 0.4 #
	smoke_sim.initial_velocity_random = 0.5
	smoke_sim.angular_velocity = 30.0 
	smoke_sim.angular_velocity_random = 1.0
	smoke_sim.linear_accel = 1.5 #
	smoke_sim.linear_accel_random = 1.0
	pass
	
func set_sparks_sim_fuel_level_1():
	sparks.emitting = false
	pass
