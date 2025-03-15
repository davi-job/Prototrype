class_name MapEdge;
extends AnimatedSprite2D;

# Edge data
@export var node_conections: Array[MapNode] = [];

## Unilateral data (only relevant if unilateral == true) 
@export_group("Unilateral options")
@export var unilateral: bool = false;
@export var open_connection: MapNode = null;

# Update node sprite
func change_frame(newFrame:int):
	frame = newFrame;
