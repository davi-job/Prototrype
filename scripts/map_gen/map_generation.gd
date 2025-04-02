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

@export var maxMapLinearSize: int = 10:
	get():
		return maxMapLinearSize * 2;

## Map definition
var map_grid: Dictionary;


# Functions

# Starts the gen
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
		
		var dungeonRooms: Array[Vector2i] = getRoomsFromGrid();
		
		if nextLevelRooms.is_empty() and dungeonRooms.size() < minRooms:
			if roomsQueue.back():
				generateDungeon(roomsQueue.back());
				return;
		
		roomsQueue = nextLevelRooms;
	
	
	
	generateLoops();
	
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

# Generate loops in the dungeon based on its leaves
func generateLoops() -> void:
	var leaves: Array[Vector2i] = getLeaves();
	
	for leaveCoord in leaves:
		# Gets conneced room direction and node
		var connectionDirecion: int = findDifferent(map_grid[leaveCoord].connections, null);
		var parentNode: MapNode = map_grid[leaveCoord].connections[connectionDirecion];
		
		# Gets all unconnected adjacent rooms
		var adjacentRooms: Array[Vector2i] = getAdjacentRooms(leaveCoord, parentNode);
		
		# Remove any adjacent room that is connected to the parent node from adjacentRooms array
		for neighborCoord in adjacentRooms:
			parentNode.connections.any(func(connection):
				if map_grid[neighborCoord] == connection:
					adjacentRooms.pop_at(adjacentRooms.find(neighborCoord));
			)
		
		adjacentRooms.any(func(neighborCoord):
			if neighborCoord.x == leaveCoord.x or neighborCoord.y == leaveCoord.y:
				connectAdjacentRooms(leaveCoord, neighborCoord);
				return true;
			
			return false;
		);

## Helper Functions

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

# Helper function that returns all rooms with only one connection (except the root)
func getLeaves() -> Array[Vector2i]:
	var leaves: Array[Vector2i];
	
	for coord in map_grid.keys():
		if coord == Vector2i.ZERO: continue;
		
		var cnctCount: int = 0;
		
		for cnct in map_grid[coord].connections:
			if cnct != null: cnctCount += 1;
		
		if cnctCount == 1: leaves.append(coord);
	
	return leaves;

# Helper function that returns an array with all unconected adjacent rooms
func getAdjacentRooms(nodeCoords: Vector2i, parentNode: MapNode) -> Array[Vector2i]:
	var directions: Dictionary = {
		"up-left": Vector2i(-2, -2),
		"up": Vector2i(0, -2),
		"up-right": Vector2i(2, -2),
		"right": Vector2i(2, 0),
		"left": Vector2i(-2, 0),
		"down-left": Vector2i(-2, 2),
		"down": Vector2i(0, 2),
		"down-right": Vector2i(2, 2),
	}
	var adjacentRooms: Array[Vector2i] = [];
	
	for dir in directions.keys():
		var neighborCoord: Vector2i = nodeCoords + directions[dir];
		if not map_grid.has(neighborCoord): continue;
		
		if map_grid[neighborCoord] == parentNode: continue;
		
		if map_grid[neighborCoord] is MapNode: adjacentRooms.append(neighborCoord);
	
	return adjacentRooms;

# Helper function that connects two adjacent rooms in a sraight connection
func connectAdjacentRooms(room1Coords: Vector2i, room2Coords: Vector2i) -> void:
	# Get the difference in each axis for posiion checks
	var xAxis: int = abs(room1Coords.x - room2Coords.x);
	var yAxis: int = abs(room1Coords.y - room2Coords.y);
	
	# Check if nodes ae direct neighbors
	if not (xAxis == 2 or yAxis == 2): return;
	
	# Check if the nodes are vertical neighbors
	var areHorizontalNeighbors: bool = (xAxis == 2);
	var newEdge: MapEdge = getEdgeNode(map_grid[room1Coords], map_grid[room2Coords]);
	var newEdgePos: Vector2i;
	
	if areHorizontalNeighbors:
		newEdgePos = Vector2i(floor(room1Coords.x + room2Coords.x)/2, room1Coords.y);
		newEdge.mapPos = newEdgePos;
		
		map_grid[newEdgePos] = newEdge;
		
		var leftNeighborCoords: Vector2i = room1Coords if room1Coords.x > room2Coords.x else room2Coords;
		var rightNeighborCoords: Vector2i = room2Coords if leftNeighborCoords == room1Coords else room1Coords;
		
		map_grid[leftNeighborCoords].connections[1] = map_grid[rightNeighborCoords];
		map_grid[rightNeighborCoords].connections[3] = map_grid[leftNeighborCoords];
		
	else:
		newEdgePos = Vector2i(room1Coords.x, floor(room1Coords.y + room2Coords.y)/2);
		newEdge.mapPos = newEdgePos;
		
		newEdge.turns = 1;
		map_grid[newEdgePos] = newEdge;
		
		var upNeighborCoords: Vector2i = room1Coords if room1Coords.y < room2Coords.y else room2Coords;
		var downNeighborCoords: Vector2i = room2Coords if upNeighborCoords == room1Coords else room1Coords;
		
		map_grid[upNeighborCoords].connections[2] = map_grid[downNeighborCoords];
		map_grid[downNeighborCoords].connections[0] = map_grid[upNeighborCoords];

# Helper function to find the first element != from value in an array and return its index
func findDifferent(arr: Array, value) -> int:
	for index in arr.size():
		if arr[index] != value: return index;
	
	return -1;

# Helper function that returns all room coords from the map_grid
func getRoomsFromGrid() -> Array[Vector2i]:
	var rooms: Array[Vector2i] = [];
	
	for nodeCoords in map_grid.keys():
		if map_grid[nodeCoords] is MapNode:  rooms.append(nodeCoords);
	
	return rooms;
