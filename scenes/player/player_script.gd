extends CharacterBody2D;

# Player movement properties
@export var speed = 90;  # Movement speed in pixels per second
@export var acceleration = 1000;  # How quickly player reaches max speed
@export var friction = 1200;  # How quickly player slows down

@onready var player_shape: CollisionShape2D = %PlayerShape;
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite;

func _physics_process(delta):
	# Get input direction vector (normalized)
	var input_direction = Input.get_vector("left", "right", "up", "down");
	input_direction = input_direction.normalized();
	
	# Handle movement with acceleration and friction
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta);
	else: 
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta);
	
	# Move the character and handle collisions
	move_and_slide();
	
	# Flip the sprite based on player velocity
	if (velocity.x != 0): player_sprite.flip_h = velocity.x < 0;
	
	# Handle player animations
	handle_animation()

func handle_animation():
	if(velocity): player_sprite.play("Walk");
	else: player_sprite.play("Idle");
