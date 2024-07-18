extends Area2D

@onready var polygon: Polygon2D = $Polygon2D;

var velocity := Vector2(350, 0);

func _process(delta):
	polygon.rotate(delta * 10)

func _physics_process(delta: float):
	velocity.y += gravity * delta;
	position += velocity * delta;
	rotation = velocity.angle()

func _on_body_entered(_body:Node):
	queue_free()
