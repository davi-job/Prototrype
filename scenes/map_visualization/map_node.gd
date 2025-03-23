class_name MapNode;
extends Node2D;

# Map data
var mapPos: Vector2i;

# Node data
# [up, righ, down, left]
var connections: Array[MapNode] = [null, null, null, null];

# Room data
@export var roomType: int = MapGeneration.roomType.NORMAL;
@export var enemyWaves: Array[EnemyWave] = [];
