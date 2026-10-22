extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 70.0
const JUMP_VELOCITY = -300.0

var status: PlayerState

var change_state: Dictionary = {
	PlayerState.idle: func():
		status = PlayerState.idle
		anim.play("idle")
		,
		
		
	PlayerState.walk: func():
		status = PlayerState.walk
		anim.play("walk"),
		
	PlayerState.jump: func():
		status = PlayerState.jump
		anim.play("jump")
}

func _ready() -> void:
	change_state[PlayerState.idle].call()

func idle_state() -> void:
	if move():
		change_state[PlayerState.walk].call()
		return
	
	if jump():
		change_state[PlayerState.jump].call()
		return
	
	
func walk_state() -> void:
	if not move():
		change_state[PlayerState.idle].call()
		return
	if jump():
		change_state[PlayerState.jump].call()
		return
		
func jump_state():
	if is_on_floor():
		if move():
			change_state[PlayerState.walk].call()
		else:
			change_state[PlayerState.walk].call()
		return
	else:
		move()

func jump() -> bool:
	if is_on_floor() and status != PlayerState.jump:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			return true
	return false
	
func move() -> bool:
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		anim.flip_h = true if direction < 0 else false
		return true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		return false


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move()
	
	match  status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
	
	move_and_slide()
