extends CharacterBody2D

enum State{
	idle,
	walk,
	jump,
	duck,
	fall,
	slide,
	dead
}

@onready var anim: AnimatedSprite2D = $Animated
@onready var collision: CollisionShape2D = $Collision
@onready var hitbox: Area2D = $Hitbox
@onready var collision_hitbox: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer


@export var speed: float = 180
@export var accelation: float = 400
@export var desaccelation: float = 400

@export var speed_slide: float = 250
@export var desaccelation_slide: float = 100

var last_position: Vector2

const jump_velocity = -300.0

const ORIGIN_SIZE: Array = [.77, 2]
const ORIGIN_POSITION: Vector2 = Vector2(0, .5)
const ORIGIN_HITBOX_SIZE: Vector2 = Vector2(20, 15)
const ORIGIN_HITBOX_POSITION: Vector2 = Vector2(0,.5)

const DUCK_SIZE: Array = [.75, 1.5]
const DUCK_POSITION: Vector2 = Vector2(0, 2)
const DUCK_HITBOX_SIZE: Vector2 = Vector2(20, 11)
const DUCK_HITBOX_POSITION: Vector2 = Vector2(0,2.5)

const SLIDE_SIZE: Array = [.72, 1.44]
const SLIDE_POSITION: Vector2 = Vector2(0, 2.5)
const SLIDE_HITBOX_SIZE: Vector2 = Vector2(20, 12)
const SLIDE_HITBOX_POSITION: Vector2 = Vector2(0,2)

var direction: float = 0

var jump_count: int = 0
@export var max_jump: int = 2

var status: State

var change_state: Dictionary = {
	State.idle: func():
		status = State.idle
		anim.play("idle"),

	State.walk: func():
		status = State.walk
		anim.play("walk"),

	State.jump: func():
		status = State.jump
		anim.play("jump"),

	State.duck: func():
		status = State.duck
		anim.play("duck")
		collision.shape.radius = DUCK_SIZE[0]
		collision.shape.height = DUCK_SIZE[1]
		collision.position = DUCK_POSITION
		collision_hitbox.shape.size = DUCK_HITBOX_SIZE
		collision_hitbox.position = DUCK_HITBOX_POSITION,

	State.fall: func():
		status = State.fall
		anim.play("fall"),

	State.slide: func():
		status = State.slide
		anim.play("slide")
		collision.shape.radius = SLIDE_SIZE[0]
		collision.shape.height = SLIDE_SIZE[1]
		collision.position = SLIDE_POSITION
		collision_hitbox.shape.size = SLIDE_HITBOX_SIZE
		collision_hitbox.position = SLIDE_HITBOX_POSITION
		velocity.x = speed_slide * direction,

	State.dead: func():
		status = State.dead
		anim.play("dead")
		velocity.x = 0
		reload_timer.start()
}

func _ready() -> void:
	change_state[State.idle].call()

func idle_state(delta: float) -> void:
	update_direction()
	if move(delta):
		change_state[State.walk].call()
		return

	if jump():

		change_state[State.jump].call()
		return

	if duck(true):
		change_state[State.duck].call()
		return

	if not is_on_floor():
		jump_count = 1
		change_state[State.fall].call()
		return

func walk_state(delta: float) -> void:
	update_direction()
	if not move(delta):
		change_state[State.idle].call()
		return
	if jump():
		change_state[State.jump].call()
		return
	if not is_on_floor():
		jump_count = 1
		change_state[State.fall].call()
		return
	if duck(true):
		change_state[State.slide].call()
		return

func jump_state(delta: float) -> void:

	if velocity.y > 0:
		change_state[State.fall].call()
		return

	update_direction()
	move(delta)

	jump()

func duck_state(delta: float) -> void:
	if not is_on_floor():
		collision.shape.radius = ORIGIN_SIZE[0]
		collision.shape.height = ORIGIN_SIZE[1]
		collision.position = ORIGIN_POSITION
		collision_hitbox.shape.size = ORIGIN_HITBOX_SIZE
		collision_hitbox.position = ORIGIN_HITBOX_POSITION
		change_state[State.fall].call()
		return

	if duck(false):
		change_state[State.idle].call()
		return
	update_direction()

	if velocity.x != 0:
		velocity.x = move_toward(velocity.x, 0, desaccelation_slide * delta)

func fall_state(delta: float) -> void:
	if is_on_floor():
		jump_count = 0
		if move(delta):
			change_state[State.walk].call()
		else:
			change_state[State.walk].call()
		return
	else:
		update_direction()
		move(delta)

		if jump():
			change_state[State.jump].call()
			return

func slide_state(delta: float) -> void:
	if not is_on_floor():
		jump_count = 1
		collision.shape.radius = ORIGIN_SIZE[0]
		collision.shape.height = ORIGIN_SIZE[1]
		collision.position = ORIGIN_POSITION
		collision_hitbox.shape.size = ORIGIN_HITBOX_SIZE
		collision_hitbox.position = ORIGIN_HITBOX_POSITION
		change_state[State.fall].call()
		return

	if duck(false):
		if is_slide_same_direction_move():
			change_state[State.walk].call()
			return
		else:
			change_state[State.idle].call()
			return
	else:
		if jump():
			change_state[State.jump].call()
			collision.shape.radius = ORIGIN_SIZE[0]
			collision.shape.height = ORIGIN_SIZE[1]
			collision.position = ORIGIN_POSITION
			collision_hitbox.shape.size = ORIGIN_HITBOX_SIZE
			collision_hitbox.position = ORIGIN_HITBOX_POSITION
			return
		elif not is_slide_same_direction_move() or last_position == position  or velocity.x == 0:
			change_state[State.duck].call()
			return
		else:
			velocity.x = move_toward(velocity.x, 0, desaccelation_slide * delta)

func dead_state(_delta: float) -> void:
	pass

func jump() -> bool:
	if Input.is_action_just_pressed("jump") and (jump_count < max_jump or max_jump == -1):
		velocity.y = jump_velocity
		jump_count += 1
		return true
	return false

func move(delta: float) -> bool:
	if direction:
		velocity.x = move_toward(velocity.x, speed * direction, accelation * delta)

		return true
	else:
		velocity.x = move_toward(velocity.x, 0, desaccelation * delta)
		return false

func update_direction():
	direction = Input.get_axis("left", "right")
	anim.flip_h = true if direction < 0 else false if direction > 0 else anim.flip_h

func duck(state: bool) -> bool:
	if state and Input.is_action_pressed("duck"):
		return true
	elif not state and Input.is_action_just_released("duck"):
		collision.shape.radius = ORIGIN_SIZE[0]
		collision.shape.height = ORIGIN_SIZE[1]
		collision.position = ORIGIN_POSITION
		return true
	else: return false



func is_slide_same_direction_move() -> bool:
	if direction == Input.get_axis("left", "right"):
		return true
	return false

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match  status:
		State.idle:
			idle_state(delta)
		State.walk:
			walk_state(delta)
		State.jump:
			jump_state(delta)
		State.duck:
			duck_state(delta)
		State.fall:
			fall_state(delta)
		State.slide:
			slide_state(delta)
		State.dead:
			dead_state(delta)
	
	last_position = position
	move_and_slide()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enimies"):
		if velocity.y:
			area.get_parent().take_damage()
			velocity.y = jump_velocity
			jump_count = 1
			change_state[State.jump].call()
		else:
			if status == State.dead: return
			change_state[State.dead].call()
	elif area.is_in_group("Projectile"):
		if status == State.dead: return
		change_state[State.dead].call()



func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
