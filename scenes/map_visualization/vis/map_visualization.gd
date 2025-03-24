extends Node2D;


# Variables

@onready var dungeon_tilemap: TileMapLayer = %dungeon_tilemap
@onready var rooms_count: RichTextLabel = %rooms_count


var map_grid: Dictionary;

# Functions

func _ready():
	MapGeneration.dungeonDone.connect(displayDungeon);

func _on_gen_btn_pressed() -> void:
	dungeon_tilemap.clear();
	MapGeneration.startGen();

func displayDungeon() -> void:
	map_grid = MapGeneration.map_grid;
	var mapCoords: Array = map_grid.keys();
	
	var room_amount: int = 0;
	
	for coord in mapCoords:
		if map_grid[coord] is MapNode:
			displayRoom(coord);
			room_amount += 1;
		elif map_grid[coord] is MapEdge: displayEdge(coord);
	
	rooms_count.text = "Rooms: " + str(room_amount);

func displayRoom(roomPos: Vector2i) -> void:
	var room: MapNode = map_grid[roomPos];
	
	dungeon_tilemap.set_cell(roomPos, 0, Vector2i(room.roomType, 0));

func displayEdge(edgePos: Vector2i) -> void:
	var edge: MapEdge = map_grid[edgePos];
	
	dungeon_tilemap.set_cell(edgePos, 0, Vector2i(edge.edgeType, 1), edge.turns);
