class_name Player extends AnimatedSprite2D

signal move_count_updated(move_count: int, push_count: int)

@onready var wall_ray: RayCast2D = $WallRay

var move_tween: Tween

var moves: Array = []
var past_moves: Array = []

var move_enabled: bool = true

var move_count: int = 0
var push_count: int = 0

func _physics_process(delta: float) -> void:
	if not move_enabled:
		return

	if Input.is_action_just_pressed("up"):
		moves.append("up")

	if Input.is_action_just_pressed("down"):
		moves.append("down")

	if Input.is_action_just_pressed("left"):
		moves.append("left")

	if Input.is_action_just_pressed("right"):
		moves.append("right")

	if Input.is_action_just_pressed("back"):
		execute_past_move()

	if moves.size() > 0 and move_tween == null:
		move(moves.pop_front())

func can_move(direction: Vector2) -> bool:
	if wall_ray.is_colliding():
		var collider: Node = wall_ray.get_collider() as Node
		if collider.is_in_group("Boxes"):
			var box: Box = collider as Box
			if box.move(direction):
				push_count += 1
				move_count_updated.emit(move_count, push_count)
				add_move(direction, box)
				return true
			else:
				return false
		else:
			return false

	add_move(direction)
	return true

func get_direction(move: String) -> Vector2:
	match move:
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		_:
			return Vector2.ZERO

func add_move(direction: Vector2, box: Box = null) -> void:
	if direction == Vector2.UP:
		past_moves.append("down")
	elif direction == Vector2.DOWN:
		past_moves.append("up")
	elif direction == Vector2.LEFT:
		past_moves.append("right")
	elif direction == Vector2.RIGHT:
		past_moves.append("left")

	if box:
		past_moves.append(box)

func move(move: String, skip_check: bool = false) -> void:
	var direction: Vector2 = get_direction(move)

	play(move + "_walk")
	wall_ray.target_position = Vector2(32,32) * direction
	wall_ray.force_raycast_update()

	if not skip_check:
		if not can_move(direction):
			return

	$WalkSound.play()
	if not skip_check:
		move_count += 1

	move_count_updated.emit(move_count, push_count)

	var new_pos: Vector2 = Vector2(self.global_position.x + (64 * direction.x), self.global_position.y + (64 * direction.y))
	move_tween = get_tree().create_tween()
	move_tween.tween_property(self, "global_position", new_pos, 0.2)
	move_tween.tween_callback(
		func() -> void:
			play(move + "_idle")
			move_tween.kill()
			move_tween = null
	)

func execute_past_move() -> void:
	if past_moves.size() < 1 or move_tween != null:
		return

	var move: Variant = past_moves.pop_back()
	var box: Box
	if typeof(move) == TYPE_STRING:
		move(move, true)
	else:
		box = move as Box
		move = past_moves.pop_back()
		box.move(get_direction(move), true)
		move(move, true)

		push_count -= 1

	move_count -= 1
	move_count_updated.emit(move_count, push_count)

func _on_coin_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group("Coins"):
		var coin: Coin = area as Coin
		$CoinSound.play()
		coin.collect()

func _on_level_level_completed() -> void:
	move_enabled = false
