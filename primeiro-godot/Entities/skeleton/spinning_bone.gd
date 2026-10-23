extends Area2D

@onready var timer: Timer = $Timer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


const speed = 100

var direction: int

func _ready() -> void:
	timer.start()
	anim.flip_h = direction < 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	position.x += speed * direction * delta

func set_direction(direction: int) -> void:
	self.direction = direction

func _on_timer_timeout() -> void:
	queue_free()


func _on_area_entered(_area: Area2D) -> void:
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
