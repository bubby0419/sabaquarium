extends Node2D

@export var speed: float = 30.0       # movement speed
@export var chase_speed: float = 90.0
@export var detect_radius: float = 250.0
@export var collect_radius: float = 30.0

enum State { WANDER, CHASE }
var state: State = State.WANDER
var wander_dir: Vector2 = Vector2.ZERO
var target_coin: Node2D = null

@onready var anim = $Sprite
@onready var wander_timer = $WanderTimer
var half_extent: Vector2
var base_sprite_y: float

@export var size_ratio: float = 0.1
@export var size_variation: float = 0.2
@export var Icon: TextureRect
@export var price: int = 2000
@export var threshold: int = 64

var bottom_line_y: float

func _ready() -> void:
	# start walking animation
	anim.play("walk")
	 # ——— calculate half_extent using the first frame texture ———
	
	var frame_tex: Texture2D = null
	var anim_name = anim.animation
	if anim.sprite_frames.has_animation(anim_name) and anim.sprite_frames.get_frame_count(anim_name) > 0:
		frame_tex = anim.sprite_frames.get_frame_texture(anim_name, 0)
	elif anim.texture:  # fallback to a plain texture if defined
		frame_tex = anim.texture
	
	var screen = get_viewport().get_visible_rect()
	
	var screen_w = screen.size.x
	var tex_w    = frame_tex.get_width()
	var base     = (screen_w * size_ratio) / tex_w
	var factor   = randf_range(1.0 - size_variation, 1.0 + size_variation)
	self.scale   = Vector2.ONE * base * factor
	
	var node_scale   = self.scale
	var sprite_scale = anim.scale
	var effective_scale = Vector2(
		node_scale.x * sprite_scale.x,
		node_scale.y * sprite_scale.y
	)
	
	if frame_tex:
		half_extent = Vector2(frame_tex.get_width(), frame_tex.get_height()) * 0.5 * effective_scale
	
	bottom_line_y = screen.position.y + screen.size.y - threshold
	
	wander_timer.timeout.connect(Callable(self, "_on_wander_timeout"))
	_start_wander()

func _process(delta: float) -> void:
	var screen = get_viewport().get_visible_rect()
	match state:
		State.WANDER:
			# — LOCK TO BOTTOM STRIP —
			position += wander_dir * speed * delta
			# compute bounds of the bottom band
			var min_x = screen.position.x + half_extent.x
			var max_x = screen.position.x + screen.size.x - half_extent.x

			var min_y = bottom_line_y - half_extent.y
			var max_y = screen.position.y + screen.size.y - half_extent.y

			# bounce horizontally
			if position.x < min_x:
				position.x = min_x
				wander_dir.x = abs(wander_dir.x)
			elif position.x > max_x:
				position.x = max_x
				wander_dir.x = -abs(wander_dir.x)

			# bounce vertically
			if position.y < min_y:
				position.y = min_y
				wander_dir.y = abs(wander_dir.y)
			elif position.y > max_y:
				position.y = max_y
				wander_dir.y = -abs(wander_dir.y)

			# — SWITCH TO CHASE IF A COIN IS CLOSE —
			var coin = _find_nearest_coin()
			if coin and coin.position.y >= bottom_line_y \
		   			and position.distance_to(coin.position) <= detect_radius:
				state = State.CHASE
				target_coin = coin

		State.CHASE:
			if target_coin and target_coin.is_inside_tree():
				# move in both X and Y towards the target
				var dir = (target_coin.position - position).normalized()
				position += dir * chase_speed * delta

				# clamp inside full screen bounds
				position.x = clamp(
					position.x,
					screen.position.x + half_extent.x,
					screen.position.x + screen.size.x - half_extent.x
				)
				position.y = clamp(
					position.y,
					screen.position.y + half_extent.y,
					screen.position.y + screen.size.y - half_extent.y
				)

				# collect if within range
				if position.distance_to(target_coin.position) <= collect_radius:
					target_coin.emit_signal("collected", target_coin)
					target_coin.queue_free()
					_start_wander()
			else:
				# lost the coin? resume wandering
				_start_wander()


	# flip so crab faces movement
	if state == State.WANDER:
		anim.flip_h = wander_dir.x < 0
	else:
		# face the target (if any)
		if target_coin:
			anim.flip_h = (target_coin.position.x - position.x) < 0

func _on_wander_timeout() -> void:
	_start_wander()

func _start_wander() -> void:
	state = State.WANDER
	# pick a random 2D direction (more horizontal bias)
	wander_dir = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-0.5, 0.5)
	).normalized()
	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.start()

func _find_nearest_coin() -> Node2D:
	var best: Node2D
	var best_dist = INF
	var coin_container = get_tree().get_current_scene().get_node("CoinContainer")
	for c in coin_container.get_children():
		var d = position.distance_to(c.position)
		if d < best_dist:
			best_dist = d
			best = c
	return best
