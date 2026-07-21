extends Node2D

const GRID_SIZE = 5
const TILE_SIZE = 64

var tiles: Array = []

func _ready() -> void:
	var grid = $GridContainer
	grid.columns = GRID_SIZE
	
	for row in range(GRID_SIZE):
		var tile_row = []
		for col in range(GRID_SIZE):
			var button = Button.new()
			button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			button.text = ""
			_set_tile_color(button, false)
			button.pressed.connect(_on_tile_pressed.bind(row, col))
			grid.add_child(button)
			tile_row.append(button)
		tiles.append(tile_row)

func _on_tile_pressed(row: int, col: int):
	var button = tiles[row][col]
	var is_on = button.get_meta("on", false)
	is_on = !is_on
	button.set_meta("on", is_on)
	_set_tile_color(button, is_on)

func _set_tile_color(button: Button, on: bool):
	var style = StyleBoxFlat.new()
	style.bg_color = Color.YELLOW if on else Color.DARK_GRAY
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
