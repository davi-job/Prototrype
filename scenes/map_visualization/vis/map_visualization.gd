extends Node2D;


# Variables

@onready var mapTilemap: TileMapLayer = %map_tilemap;

const MAP_NODE: PackedScene = preload("res://scenes/map_visualization/map_node.tscn");
const MAP_EDGE: PackedScene = preload("res://scenes/map_visualization/map_edge.tscn");


# Functions

func getMapNode(nodeRoomType: MapGeneration.roomType = MapGeneration.roomType.NORMAL) -> MapNode:
	var newNode = MAP_NODE.instantiate();
	newNode.roomType = nodeRoomType;
	
	return newNode;

func drawMapNode(pos: Vector2i, nodeRoomType: MapGeneration.roomType = MapGeneration.roomType.NORMAL) -> void:
	mapTilemap.set_cell(pos, 0, Vector2i(nodeRoomType, 0));

func drawMapEdge(pos: Vector2i, mapEdgeType: MapGeneration.edgeType = MapGeneration.edgeType.NORMAL, turns: int = 0) -> void:
	if turns < 0: return;
	if turns > 3: return;
	
	if mapEdgeType == MapGeneration.edgeType.NORMAL and turns > 1: turns = 1;
	
	mapTilemap.set_cell(pos, 0, Vector2i(mapEdgeType, 1), turns);
