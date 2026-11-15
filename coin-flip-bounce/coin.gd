extends RigidBody2D

signal coin_settled(result: String)

@export var heads_texture: Texture2D
@export var tails_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var is_active: bool = false
var is_settling: bool = false
var current_side: String = "Heads"
var settle_timer: float = 0.0
var max_flight_timer: float = 0.0
var base_scale: Vector2 = Vector2.ONE

var flip_angle: float = 0.0
var flip_speed: float = 0.0
var land_tween: Tween

func _ready() -> void:
	base_scale = sprite.scale
	if heads_texture:
		sprite.texture = heads_texture
	
	contact_monitor = true
	max_contacts_reported = 2
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func flip_coin() -> void:
	if is_active or is_settling:
		return
	
	if land_tween and land_tween.is_valid():
		land_tween.kill()
	
	freeze = false
	sleeping = false
	
	is_active = true
	is_settling = false
	settle_timer = 0.0
	max_flight_timer = 0.0
	flip_angle = 0.0
	
	var is_heads: bool = randi() % 2 == 0
	current_side = "Heads" if is_heads else "Tails"
	
	linear_velocity = Vector2.ZERO
	angular_velocity = randf_range(-10.0, 10.0)
	var random_x: float = randf_range(-200.0, 200.0)
	apply_central_impulse(Vector2(random_x, -900.0))
	
	flip_speed = 38.0

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	max_flight_timer += delta
	var speed: float = linear_velocity.length()
	
	# Spin speed follows velocity
	var target_spin_speed: float = clamp(speed * 0.045, 4.5, 42.0)
	flip_speed = lerp(flip_speed, target_spin_speed, delta * 5.0)
	flip_angle = wrapf(flip_angle + flip_speed * delta, 0.0, TAU)
	
	_update_visual(flip_angle)
	
	# Safety timeout so it never gets stuck forever
	if max_flight_timer >= 100:
		is_active = false
		_start_landing()
		return
	
	# Check if coin has stopped bouncing
	if speed < 25.0:
		settle_timer += delta
		if settle_timer >= 0.35:
			var showing_heads: bool = cos(flip_angle) >= 0.0
			var on_target: bool = (showing_heads and current_side == "Heads") or (not showing_heads and current_side == "Tails")
			if on_target:
				is_active = false
				_start_landing()
	else:
		settle_timer = 0.0

func _update_visual(angle: float) -> void:
	var cos_val: float = cos(angle)
	sprite.scale.x = base_scale.x * abs(cos_val)
	sprite.scale.y = base_scale.y
	if heads_texture and tails_texture:
		sprite.texture = heads_texture if cos_val >= 0.0 else tails_texture

func _start_landing() -> void:
	is_settling = true
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_deferred("freeze", true)
	
	var target_angle: float = 0.0 if current_side == "Heads" else PI
	var final_angle: float = flip_angle + angle_difference(flip_angle, target_angle)
	
	# Only finishes the flat face un-squish; leaves self.rotation untouched where it landed
	land_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	land_tween.tween_method(_update_visual, flip_angle, final_angle, 0.2)
	land_tween.finished.connect(_on_landing_done)

func _on_landing_done() -> void:
	is_settling = false
	sprite.scale = base_scale
	if heads_texture and tails_texture:
		sprite.texture = heads_texture if current_side == "Heads" else tails_texture
	coin_settled.emit(current_side)

func _on_body_entered(_body: Node) -> void:
	if not is_active:
		return
	
	var impact_speed: float = linear_velocity.length()
	if impact_speed > 80.0:
		flip_speed = max(flip_speed, clamp(impact_speed * 0.05, 12.0, 35.0))
		apply_central_impulse(Vector2(randf_range(-55.0, 55.0), 0.0))
