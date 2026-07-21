extends Node2D

const GRID_SIZE = 5
const TILE_SIZE = 64

var tiles: Array = []

func _ready() -> void:
	var border_style = StyleBoxFlat.new()
	border_style.content_margin_left = 64
	border_style.content_margin_right = 64
	border_style.content_margin_top = 64
	border_style.content_margin_bottom = 64
	border_style.border_color = Color(0, 0, 0, 0)
	border_style.bg_color = Color(0, 0, 0, 0)
	$GridBorder.add_theme_stylebox_override("panel", border_style)
	
	var grid = $GridBorder/GridContainer
	grid.columns = GRID_SIZE
	
	$WinLabel.visible = false
	
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
	
	_generate_puzzle(15)

func _generate_puzzle(num_shuffles: int):
	$WinLabel.visible = false
	randomize()
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			tiles[row][col].set_meta("on", false)
			_set_tile_color(tiles[row][col], false)
	
	for i in range(num_shuffles):
		var row = randi() % GRID_SIZE
		var col = randi() % GRID_SIZE
		_toggle_tile(row, col)
		_toggle_tile(row - 1, col)
		_toggle_tile(row + 1, col)
		_toggle_tile(row, col - 1)
		_toggle_tile(row, col + 1)

func _on_tile_pressed(row: int, col: int):
	_toggle_tile(row, col)
	_toggle_tile(row - 1, col)
	_toggle_tile(row + 1, col)
	_toggle_tile(row, col - 1)
	_toggle_tile(row, col + 1)
	check_win()

func _set_tile_color(button: Button, on: bool):
	var style = StyleBoxFlat.new()
	style.bg_color = Color.YELLOW if on else Color.DARK_GRAY
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

func _toggle_tile(row: int, col: int):
	if row < 0 or row >= GRID_SIZE or col < 0 or col >= GRID_SIZE:
		return
	var button = tiles[row][col]
	var is_on = button.get_meta("on", false)
	is_on = !is_on
	button.set_meta("on", is_on)
	_set_tile_color(button, is_on)

func check_win():
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if tiles[row][col].get_meta("on", false):
				return
	on_win()

func on_win():
	$WinLabel.visible = true

func solve() -> Array:
	var n = GRID_SIZE * GRID_SIZE
	var A = []
	var b = []
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var i = row * GRID_SIZE + col
			var coeffs = []
			coeffs.resize(n)
			coeffs.fill(0)
			coeffs[i] = 1
			if row > 0: coeffs[i - GRID_SIZE] = 1
			if row < GRID_SIZE - 1: coeffs[i + GRID_SIZE] = 1
			if col > 0: coeffs[i - 1] = 1
			if col < GRID_SIZE - 1: coeffs[i + 1] = 1
			A.append(coeffs)
			b.append(1 if tiles[row][col].get_meta("on", false) else 0)
	
	var rank = 0
	for c in range(n):
		var pivot = -1
		for r in range(rank, n):
			if A[r][c] == 1:
				pivot = r
				break
		if pivot == -1:
			continue
		var tmp = A[rank]
		A[rank] = A[pivot]
		A[pivot] = tmp
		var tmp_b = b[rank]
		b[rank] = b[pivot]
		b[pivot] = tmp_b
		
		for r in range(n):
			if r != rank and A[r][c] == 1:
				for cc in range(n):
					A[r][cc] = A[r][cc] ^ A[rank][cc]
				b[r] = b[r] ^ b[rank]
		rank += 1
	
	var x = []
	x.resize(n)
	x.fill(0)
	for r in range(n):
		for c in range(n):
			if A[r][c] == 1:
				x[c] = b[r]
				break
	
	var moves = []
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var i = row * GRID_SIZE + col
			if x[i] == 1:
				moves.append(Vector2i(row, col))
	return moves


func _on_solve_button_pressed() -> void:
	var moves = solve()
	for move in moves:
		_on_tile_pressed(move.x, move.y)


func _on_restart_button_pressed() -> void:
	_generate_puzzle(15)
