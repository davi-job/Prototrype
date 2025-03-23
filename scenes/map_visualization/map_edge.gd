class_name MapEdge;
extends Node2D;

# Map data
var mapPos: Vector2i;

# Edge data
@export var edgeType: int = MapGeneration.edgeType.NORMAL;
@export var turns: int = 0;

@export var connections: Array[MapNode] = [null, null];

## Unilateral data (only relevant if unilateral == true) 
@export_group("Unilateral options")
@export var unilateral: bool = false;
@export var openConnectionIndex: int;
