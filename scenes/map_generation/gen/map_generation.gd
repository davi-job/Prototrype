extends Node2D;

enum room_type {NORMAL, ENTRANCE, HUB, REWARD, BOSS, EXIT};

const MAP_NODE: PackedScene = preload("res://scenes/map_generation/map_node.tscn");
const MAP_EDGE: PackedScene = preload("res://scenes/map_generation/map_edge.tscn");
