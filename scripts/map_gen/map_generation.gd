extends Node


# Variables

## Room and Edge types enums
enum roomType {NORMAL, ENTRANCE, HUB, REWARD, BOSS, EXIT};
enum edgeType {NORMAL, UNILTERAL, CORNER};

## Management room and edge nodes
const MAP_NODE: PackedScene = preload("res://scenes/map_visualization/map_node.tscn");
const MAP_EDGE: PackedScene = preload("res://scenes/map_visualization/map_edge.tscn");

## Generation vars
@export var minRooms: int = 5;
@export var maxRooms: int = 8;
@onready var roomQuantity: int = randi_range(minRooms, maxRooms); # Does not include root

@export var roomSpawnChance: int = 100:
	get:
		if roomSpawnChance <= 0: return 1;
		elif roomSpawnChance > 100: return 100;
		else: return roomSpawnChance;

@export var maxMapLinearSize: int = 5:
	get():
		return maxMapLinearSize * 2;

## Map definition
var map_grid: Dictionary = {};


# Functions

func _ready() -> void:
	setMapRoot();
	generateRooms(Vector2i(0, 0));

func setMapRoot() -> void:
	var root: MapNode = getMapNode(roomType.ENTRANCE);
	
	root.mapPos = Vector2i(0, 0);
	map_grid[Vector2i(0, 0)] = root;

func generateRooms(parentRoomPos: Vector2i) -> void:
	if roomQuantity <= 0: return;
	
	## Set connections array and continuously cycle trhought it trying to successfully connect a least 1
	var connections: Array[bool];
	connections = setConnections(connections, parentRoomPos);
	
	## Create and connect rooms and edges in all successful connections
	connectNewRooms(connections, parentRoomPos);
	
	# Test prints
	#print(roomQuantity);
	#print(map_grid);

func setConnections(connections: Array[bool], parentRoomPos: Vector2i) -> Array[bool]:
	while not connections.any(func(connection): return connection):
		connections = [];
		
		for direction in 4:
			if randi_range(1, 100) <= roomSpawnChance and not map_grid[parentRoomPos].connections[direction]:
				connections.append(true);
			else:
				connections.append(false);
	
	return connections;

func connectNewRooms(connections: Array[bool], parentRoomPos: Vector2i) -> void:
	for index in connections.size():
		if not connections[index]: continue;
		roomQuantity -= 1;
		
		var newRoom = getMapNode(MapGeneration.roomType.NORMAL);
		map_grid[parentRoomPos].connections[index] = newRoom;
		
		var connectingEdge: MapEdge = getEdgeNode(map_grid[parentRoomPos], newRoom);
		
		var newRoomPos: Vector2i;
		var connectingEdgePos:Vector2i;
		
		## UP
		if index == 0: 
			newRoomPos = parentRoomPos + (2 * Vector2i.DOWN);
			connectingEdgePos = parentRoomPos + Vector2i.DOWN;
			
			### Setup new room connection
			newRoom.connections[2] = map_grid[parentRoomPos];
			
			### Setup connecting edge data
			if connectingEdge.edgeType == edgeType.NORMAL:
				connectingEdge.turns = 1;
			elif connectingEdge.edgeType == edgeType.UNILTERAL:
				connectingEdge.turns = 3;
		
		## Right
		elif index == 1: 
			newRoomPos = parentRoomPos + (2 * Vector2i.RIGHT);
			connectingEdgePos = parentRoomPos + Vector2i.RIGHT;
			
			### Setup new room connection
			newRoom.connections[3] = map_grid[parentRoomPos];
		
		## Down
		elif index == 2:
			newRoomPos = parentRoomPos + (2 * Vector2i.UP);
			connectingEdgePos = parentRoomPos + Vector2i.UP;
			
			### Setup new room connection
			newRoom.connections[0] = map_grid[parentRoomPos];
			
			### Setup connecting edge data
			if connectingEdge.edgeType == edgeType.NORMAL:
				connectingEdge.turns = 1;
			elif connectingEdge.edgeType == edgeType.UNILTERAL:
				connectingEdge.turns = 1;
		
		## Left
		elif index == 3:
			newRoomPos = parentRoomPos + (2 * Vector2i.LEFT);
			connectingEdgePos = parentRoomPos + Vector2i.LEFT;
			
			### Setup new room connection
			newRoom.connections[1] = map_grid[parentRoomPos];
			
			### Setup connecting edge data
			if connectingEdge.edgeType == edgeType.UNILTERAL:
				connectingEdge.turns = 2;
		
		
		newRoom.mapPos = newRoomPos;
		map_grid[connectingEdgePos] = connectingEdge;
		map_grid[newRoomPos] = newRoom;
		
		# Test prints
		#print("Root connections:")
		#print(map_grid[parentRoomPos].connections);
		#
		#print("New room connections and pos:")
		#print(newRoom.connections);
		#print(newRoom.mapPos);

func getMapNode(nodeRoomType: roomType = roomType.NORMAL) -> MapNode:
	var newNode = MAP_NODE.instantiate();
	newNode.roomType = nodeRoomType;
	
	return newNode;

func getEdgeNode(from: MapNode, to: MapNode, mapEdgeType: edgeType = edgeType.NORMAL, turns: int = 0) -> MapEdge:
	var newEdge = MAP_EDGE.instantiate();
	newEdge.edgeType = mapEdgeType;
	newEdge.turns = turns;
	
	newEdge.connections[0] = from;
	newEdge.connections[1] = to;
	
	return newEdge;
