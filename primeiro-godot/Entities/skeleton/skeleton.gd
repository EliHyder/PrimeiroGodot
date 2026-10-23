extends CharacterBody2D

enum State {
	walk,
	throw,
	dead
}
@onready var anim: AnimatedSprite2D = $Animated
@onready var hitbox: Area2D = $Hitbox
@onready var collision: CollisionShape2D = $Collision
@onready var wall_detector: RayCast2D = $WallDetector
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_point: Node2D = $BonePoint

const SPINNING_BONE = preload("uid://ccon4idv1ihc0")


const SPEED: float = 30.0
const JUMP_VELOCITY: float = -400.0

var direction: int = 1

var can_throw: bool = true

var status: State

var change_state = {
	
	State.walk: func():
		status = State.walk
		anim.play("walk")
		can_throw = true,
		
	State.throw: func():
		status = State.throw
		velocity.x = 0
		anim.play("throw"),
		
	State.dead: func():
		set_meta("Dead", true)
		velocity.x = 0
		status = State.dead
		anim.play("dead")
		hitbox.process_mode = Node.PROCESS_MODE_DISABLED,
	
}

func _ready() -> void:
	status = State.walk

func walk_state(_delta:float) -> void:
	velocity.x = SPEED * direction
	
	if player_detector.is_colliding():
		change_state[State.throw].call()
		return
	
	if wall_detector.is_colliding() or not floor_detector.is_colliding():
		direction *= -1
		anim.flip_h = direction < 0
		wall_detector.target_position.x *= -1
		floor_detector.position.x *= -1
		player_detector.target_position.x *= -1
		
	

func throw_state(_delta: float):
	if anim.frame == 2 and can_throw :
		can_throw = false
		throw_bone()
	
func dead_state(_delta: float) -> void:
	pass

func take_damage() -> void:
	change_state[State.dead].call()

func throw_bone() -> void:
	var new_bone = SPINNING_BONE.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_point.global_position
	new_bone.set_direction(self.direction)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		State.walk:
			walk_state(delta)
		State.throw:
			throw_state(delta)
		State.dead:
			dead_state(delta)
		

	move_and_slide()

func _on_animated_animation_finished() -> void:
	if anim.animation == "throw":
		change_state[State.walk].call()
