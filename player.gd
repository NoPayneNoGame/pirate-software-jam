# @tool
extends CharacterBody2D

@onready var Potion = preload("res://potion.tscn");
@onready var hand = $Hand

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var throw_strength := 750.0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# var mouse_position: Vector2;
var point_1 = Vector2(0, -40);
var point_2: Vector2;

var default_font: Font;
var default_font_size: int;

var max_points = 50;
var line: PackedVector2Array = [];

func _ready():
	default_font = ThemeDB.fallback_font;
	default_font_size = ThemeDB.fallback_font_size;

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		var mouse_position = to_local(event.position)
		if mouse_position != point_2:
			point_2 = mouse_position

func update_trajectory(delta: float) -> void:
	line = [];
	var pos: Vector2 = hand.global_position;
	var vel: Vector2 = hand.global_transform.x * throw_strength;
	for i in max_points:
		line.append(to_local(pos))
		vel.y += gravity * delta;
		pos += vel * delta;

func throw():
	var p = Potion.instantiate()
	owner.add_child(p)

	p.transform = hand.global_transform
	p.velocity = p.transform.x * throw_strength;

func get_mouse_position_tool() -> Vector2:
	var root = self.get_parent();
	var container: SubViewportContainer = root.get_parent().get_parent()

	if not container:
		return Vector2.ZERO;

	var viewport := root.get_viewport()

	var screen_mouse := container.get_local_mouse_position() / viewport.global_canvas_transform.get_scale()
	var translation := viewport.global_canvas_transform.get_origin() / viewport.global_canvas_transform.get_scale()
	return screen_mouse - translation

func _process(_delta: float):
	if Engine.is_editor_hint():
		var mouse_position = to_local(get_mouse_position_tool())
		if mouse_position != point_2:
			point_2 = mouse_position

	hand.look_at(to_global(point_2))

	if Input.is_action_just_pressed("throw"):
		throw();
	queue_redraw()

func _physics_process(delta: float):
	if Engine.is_editor_hint():
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_trajectory(delta)
	queue_redraw()

func sample_parabola(start: Vector2, end: Vector2, height: float, t: float) -> Vector2:
	var _start := Vector3(start.x, start.y, 0);
	var _end := Vector3(end.x, end.y, 0);

	var parabolic_t := t * 2.0 - 1.0;

	if abs(start.y - end.y) < 0.1:
		var travel_direction := end - start;
		var result = start + t * travel_direction;
		result.y += (-parabolic_t * parabolic_t + 1) * height;
		return result

	else:
		var travel_direction := _end - _start;
		var level_direction := _end - Vector3(start.x, end.y, 0);
		var right = travel_direction.cross(level_direction);
		var up = right.cross(travel_direction)

		if end.y < start.y:
			up = -up
		var result := _start + t * travel_direction;
		result += ((-parabolic_t * parabolic_t + 1) * height) * up.normalized();
		return Vector2(result.x, result.y);


func _draw():
	# if point_2.y > 0:
	# 	point_2.y = 0;

	draw_polyline(line, Color.WHITE);

	# draw_string(default_font, point_2, str(point_2));
