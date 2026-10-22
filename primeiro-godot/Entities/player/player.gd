extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump,
	duck,
	fall
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


@export var speed: float
@export var accelation: float
@export var desaccelation: float


const jump_velocity = -300.0

const ORIGIN_SIZE: Array = [.77, 2]
const ORIGIN_POSITION: Vector2 = Vector2(0, .5)
const DUCK_SIZE: Array = [.75, 1.5]
const DUCK_POSITION: Vector2 = Vector2(0, 2)

var direction: float = 0

var jump_count: int = 0
@export var max_jump: int

var status: PlayerState

var change_state: Dictionary = {
	PlayerState.idle: func():
		status = PlayerState.idle
		anim.play("idle"),
		
	PlayerState.walk: func():
		status = PlayerState.walk
		anim.play("walk"),
		
	PlayerState.jump: func():
		status = PlayerState.jump
		anim.play("jump"),
		
	PlayerState.duck: func():
		status = PlayerState.duck
		anim.play("duck"),
		
	PlayerState.fall: func():
		status = PlayerState.fall
		anim.play("fall")
}

func _ready() -> void:
	change_state[PlayerState.idle].call()

func idle_state(delta: float) -> void:
	update_direction()
	if move(delta):
		change_state[PlayerState.walk].call()
		return
	
	if jump():
		
		change_state[PlayerState.jump].call()
		return
	
	if duck(true):
		change_state[PlayerState.duck].call()
		return
	
	if not is_on_floor():
		jump_count = 1
		change_state[PlayerState.fall].call()
		return
	
func walk_state(delta: float) -> void:
	update_direction()
	if not move(delta):
		change_state[PlayerState.idle].call()
		return
	if jump():
		change_state[PlayerState.jump].call()
		return
	if not is_on_floor():
		jump_count = 1
		change_state[PlayerState.fall].call()
		return
	
		
func jump_state(delta: float):
	
	if velocity.y > 0:
		change_state[PlayerState.fall].call()
		return
	
	update_direction()
	move(delta)
		
	jump()
	
	
func duck_state(_delta: float):
	if duck(false):
		change_state[PlayerState.idle].call()
		return
	update_direction()
	if not is_on_floor():
		change_state[PlayerState.fall].call()
		return
	
func fall_state(delta: float):
	if is_on_floor():
		jump_count = 0
		if move(delta):
			change_state[PlayerState.walk].call()
		else:
			change_state[PlayerState.walk].call()
		return
	else:
		update_direction()
		move(delta)
			
		if jump():
			change_state[PlayerState.jump].call()
			return
	
	
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
		collision.shape.radius = DUCK_SIZE[0]
		collision.shape.height = DUCK_SIZE[1]
		collision.position = DUCK_POSITION
		return true
	elif not state and Input.is_action_just_released("duck"):
		collision.shape.radius = ORIGIN_SIZE[0]
		collision.shape.height = ORIGIN_SIZE[1]
		collision.position = ORIGIN_POSITION
		return true	
	else: return false
		


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	
	
	match  status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.fall:
			fall_state(delta)
			
	move_and_slide()
