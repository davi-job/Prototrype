class_name MapNode;
extends AnimatedSprite2D;


# Node data
# [up, righ, down, left]
var conections: Array[int] = [0, 0, 0, 0];

# Room data
@export var room_type: int = MapGeneration.room_type.NORMAL;
@export var enemy_waves: Array[EnemyWave] = [];

# Update node sprite
func change_frame(newFrame:int):
	frame = newFrame;
