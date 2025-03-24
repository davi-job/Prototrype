extends Node
signal dungeonDone

# Variables

## Room and Edge types enums
enum roomType {NORMAL, ENTRANCE, HUB, REWARD, BOSS, EXIT};
enum edgeType {NORMAL, UNILTERAL, CORNER};

## Room and edge nodes
const MAP_NODE: PackedScene = preload("uid://cmxvkb5xl5vsx");
const MAP_EDGE: PackedScene = preload("uid://cfk4c8u53jxce");

## Generation vars
@export var minRooms: int = 10;
@export var maxRooms: int = 15;
@onready var roomQuantity: int; # Does not include root

@export var roomSpawnChance: int = 65:
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

func startGen() -> void:
	map_grid = {};
	roomQuantity = randi_range(minRooms, maxRooms);
	
	setMapRoot();
	generateDungeon(Vector2i(0, 0));

# Sets the root on the (0, 0) pos
func setMapRoot() -> void:
	var root: MapNode = getMapNode(roomType.ENTRANCE);
	
	root.mapPos = Vector2i(0, 0);
	map_grid[Vector2i(0, 0)] = root;

# Generate new rooms from parentRoomPos
func generateDungeon(startingPos: Vector2i) -> void:
	if roomQuantity <= 0: return;
	
	var roomsQueue: Array[Vector2i] = [startingPos];
	
	while roomsQueue.size() > 0 and roomQuantity > 0:
		var nextLevelRooms: Array[Vector2i] = [];
		
		for currentRoom in roomsQueue:
			# Create connections array to keep track of the room connections
			var connections: Array[bool];
			for connection in map_grid[currentRoom].connections:
				connections.append(connection != null)
			
			# Set which connections will have new rooms
			connections = setConnections(connections, currentRoom);
			
			# Create and connect new rooms for all successful connections
			var newRoomPositions = generateConnectingRooms(connections, currentRoom);
			
			nextLevelRooms.append_array(newRoomPositions);
		
		roomsQueue = nextLevelRooms;
	
	dungeonDone.emit();

# Cycles trhought the connections array trying to connect a new room
func setConnections(connections: Array[bool], parentRoomPos: Vector2i) -> Array[bool]:
	for direction in range(4):
		# If there's already a connection, continue to the next number
		if connections[direction]: continue;
		
		# Calculate new room position
		var newRoomPos: Vector2i = getNewRoomPos(parentRoomPos, direction)
		
		# Check if new connection would go out of the map max size
		if newRoomPos.x > maxMapLinearSize or newRoomPos.x < -maxMapLinearSize: continue;
		if newRoomPos.y > maxMapLinearSize or newRoomPos.y < -maxMapLinearSize: continue;
		
		# Check if position is already occupied
		if map_grid.has(newRoomPos): continue
		
		# Tries to connect new room
		if randi_range(0, 100) <= roomSpawnChance and roomQuantity > 0:
			connections[direction] = true;
			roomQuantity -= 1;
	
	# If the parent is the root and did't connect any new rooms, try again.
	if parentRoomPos == Vector2i(0, 0) and not connections.any(func(connection): return connection):
		setConnections(connections, parentRoomPos);
	
	return connections;

# Creates and connects rooms and edges in all successful connections in the connections array
func generateConnectingRooms(connections: Array[bool], parentRoomPos: Vector2i) -> Array[Vector2i]:
	var parentRoomChildrenPos: Array[Vector2i] = [];
	
	for direction in connections.size():
		if not connections[direction]: continue;
		
		# Calculate positions using helper functions
		var newRoomPos = getNewRoomPos(parentRoomPos, direction);
		var connectingEdgePos = getEdgePos(parentRoomPos, direction);
		
		# Check if position is already occupied
		if map_grid.has(newRoomPos): continue;
		
		# Setup new room and new edge
		var newRoom = getMapNode(MapGeneration.roomType.NORMAL);
		var connectingEdge: MapEdge = getEdgeNode(map_grid[parentRoomPos], newRoom);
		
		# Set new room and edge map position property
		newRoom.mapPos = newRoomPos;
		connectingEdge.mapPos = connectingEdgePos;
		
		# Set edge rotation
		connectingEdge.turns = getEdgeRotation(direction, connectingEdge.edgeType);
		
		# Insert new room into the parent's connections array
		map_grid[parentRoomPos].connections[direction] = newRoom;
		
		# Insert parent room into new room's connections array
		# (opposite direction from the original connection)
		var oppositeDirection = (direction + 2) % 4;
		newRoom.connections[oppositeDirection] = map_grid[parentRoomPos];
		
		# Insert new room and edge into the map grid
		map_grid[newRoomPos] = newRoom;
		map_grid[connectingEdgePos] = connectingEdge;
		
		parentRoomChildrenPos.append(newRoomPos);
	
	return parentRoomChildrenPos;

# Helper function to create a new room node
func getMapNode(nodeRoomType: roomType = roomType.NORMAL) -> MapNode:
	var newNode = MAP_NODE.instantiate();
	newNode.roomType = nodeRoomType;
	
	return newNode;

# Helper function to create a new edge node
func getEdgeNode(from: MapNode, to: MapNode, mapEdgeType: edgeType = edgeType.NORMAL, turns: int = 0) -> MapEdge:
	var newEdge = MAP_EDGE.instantiate();
	newEdge.edgeType = mapEdgeType;
	newEdge.turns = turns;
	
	newEdge.connections[0] = from;
	newEdge.connections[1] = to;
	
	return newEdge;

# Helper function to calculate new room position based on parent position and direction
func getNewRoomPos(parentPos: Vector2i, direction: int) -> Vector2i:
	match direction:
		0: return parentPos + (2 * Vector2i.UP);    # Up
		1: return parentPos + (2 * Vector2i.RIGHT); # Right  
		2: return parentPos + (2 * Vector2i.DOWN);  # Down
		3: return parentPos + (2 * Vector2i.LEFT);  # Left
		_: return Vector2i.ZERO; # Fallback, shouldn't happen

# Helper function to calculate edge position between parent and new room
func getEdgePos(parentPos: Vector2i, direction: int) -> Vector2i:
	match direction:
		0: return parentPos + Vector2i.UP;    # Up
		1: return parentPos + Vector2i.RIGHT; # Right  
		2: return parentPos + Vector2i.DOWN;  # Down
		3: return parentPos + Vector2i.LEFT;  # Left
		_: return Vector2i.ZERO; # Fallback, shouldn't happen

# Helper function to set edge rotation based on direction and edge type
func getEdgeRotation(direction: int, mapEdgeType: int) -> int:
	match mapEdgeType:
		MapGeneration.edgeType.NORMAL:
			return 1 if direction == 0 or direction == 2 else 0;
		
		MapGeneration.edgeType.UNILTERAL, MapGeneration.edgeType.CORNER:
			match direction:
				0: return 3; # Up
				1: return 0; # Right
				2: return 1; # Down
				3: return 2; # Left
	
	return 0; # Default rotation
