extends Node2D

var GRID_SIZE: int = 5
var TILE_SIZE: int = 64

const TOTAL_GRID_PIXELS = 320

var tiles: Array = []
var click_count: int = 0
var move_history: Array = []
var current_difficulty: int = 15
var hinted_cells: Array = []
var optimal_clicks: int = 0

func _ready() -> void:
	$SizeControls/Size3Button.pressed.connect(_on_size_pressed.bind(3))
	$SizeControls/Size4Button.pressed.connect(_on_size_pressed.bind(4))
	$SizeControls/Size5Button.pressed.connect(_on_size_pressed.bind(5))
	$SizeControls/Size7Button.pressed.connect(_on_size_pressed.bind(7))
	var border_style = StyleBoxFlat.new()
	border_style.content_margin_left = 64
	border_style.content_margin_right = 64
	border_style.content_margin_top = 64
	border_style.content_margin_bottom = 64
	border_style.border_color = Color(0, 0, 0, 0)
	border_style.bg_color = Color(0, 0, 0, 0)
	$GridBorder.add_theme_stylebox_override("panel", border_style)
	
	$WinLabel.visible = false
	$ClickCountLabel.text = "Clicks: 0"
	
	build_grid()
	_generate_puzzle(current_difficulty)

func _on_size_pressed(new_size: int):
	GRID_SIZE = new_size
	build_grid()
	_generate_puzzle(current_difficulty)

func build_grid():
	TILE_SIZE = int(TOTAL_GRID_PIXELS / float(GRID_SIZE))
	var grid = $GridBorder/GridContainer
	
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
	tiles.clear()
	
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

func _generate_puzzle(num_shuffles: int):
	$WinLabel.visible = false
	click_count = 0
	move_history.clear()
	clear_hints()
	$ClickCountLabel.text = "Clicks: 0"
	$ClickCountLabel.visible = true
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
	
	optimal_clicks = solve().size()

func _on_tile_pressed(row: int, col: int):
	clear_hints()
	_toggle_tile(row, col)
	_toggle_tile(row - 1, col)
	_toggle_tile(row + 1, col)
	_toggle_tile(row, col - 1)
	_toggle_tile(row, col + 1)
	move_history.append(Vector2i(row, col))
	click_count += 1
	$ClickCountLabel.text = "Clicks: " + str(click_count)
	check_win()

func _set_tile_color(button: Button, on: bool, animate: bool = true):
	var style = StyleBoxFlat.new()
	style.bg_color = Color.YELLOW if on else Color.DARK_GRAY
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	
	if animate:
		button.pivot_offset = button.size / 2
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.08)

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
	$ClickCountLabel.visible = false
	$WinLabel.visible = true
	$WinLabel.text = "You won! \n(%d clicks - optimal: %d)" % [click_count, optimal_clicks]
	animate_win()

func animate_win():
	$WinLabel.scale = Vector2(0.5, 0.5)
	$WinLabel.pivot_offset = $WinLabel.size / 2
	var label_tween = create_tween()
	label_tween.tween_property($WinLabel, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label_tween.tween_property($WinLabel, "scale", Vector2(1.0, 1.0), 0.1)
	
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var button = tiles[row][col]
			var delay = (row + col) * 0.03
			var flash_tween = create_tween()
			flash_tween.tween_interval(delay)
			flash_tween.tween_callback(func():
				var style = StyleBoxFlat.new()
				style.bg_color = Color.WHITE
				button.add_theme_stylebox_override("normal", style)
			)
			flash_tween.tween_interval(0.08)
			flash_tween.tween_callback(func():
				var style = StyleBoxFlat.new()
				style.bg_color = Color.DARK_GRAY
				button.add_theme_stylebox_override("normal", style)
			)

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
	clear_hints()
	var moves = solve()
	for move in moves:
		_on_tile_pressed(move.x, move.y)


func _on_restart_button_pressed() -> void:
	_generate_puzzle(current_difficulty)


func _on_undo_button_pressed() -> void:
	if move_history.is_empty():
		return
	var last_move = move_history.pop_back()
	_toggle_tile(last_move.x, last_move.y)
	_toggle_tile(last_move.x - 1, last_move.y)
	_toggle_tile(last_move.x + 1, last_move.y)
	_toggle_tile(last_move.x, last_move.y - 1)
	_toggle_tile(last_move.x, last_move.y + 1)
	click_count -= 1
	$ClickCountLabel.text = "Clicks: " + str(click_count)
	$WinLabel.visible = false


func _on_easy_button_pressed() -> void:
	current_difficulty = 5
	_generate_puzzle(current_difficulty)


func _on_medium_button_pressed() -> void:
	current_difficulty = 15
	_generate_puzzle(current_difficulty)


func _on_hard_button_pressed() -> void:
	current_difficulty = 30
	_generate_puzzle(current_difficulty)


func _on_hint_button_pressed() -> void:
	clear_hints()
	var moves = solve()
	hinted_cells = moves
	for move in moves:
		var button = tiles[move.x][move.y]
		button.add_theme_color_override("font_color", Color.RED)
		button.text = "•"

func clear_hints():
	for cell in hinted_cells:
		var button = tiles[cell.x][cell.y]
		button.text = ""
	hinted_cells.clear()
