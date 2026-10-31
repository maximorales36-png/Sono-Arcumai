# Dibuja la grilla, las notas de la capa activa, las líneas de barrido y el cursor parpadeante.
# Solo lee el estado: no lo modifica. Depende de config.gd, state.gd y sequencer.gd.
class_name View
extends Node2D

var state: State
var sequencer: Sequencer


func _ready() -> void:
	assert(state != null, "[view] falta el State: main.gd tiene que asignarlo antes de agregar el nodo")
	assert(sequencer != null, "[view] falta el Sequencer: main.gd tiene que asignarlo antes de agregar el nodo")
	assert(
		Config.LAYER_COLORS.size() == Config.LAYER_COUNT,
		"[view] LAYER_COLORS tiene %d colores y hay %d capas" % [Config.LAYER_COLORS.size(), Config.LAYER_COUNT]
	)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var grid_rect := _grid_rect()
	var cell_size := Vector2(
		grid_rect.size.x / float(Config.STEPS),
		grid_rect.size.y / float(Config.ROWS)
	)
	_draw_grid_lines(grid_rect, cell_size)
	_draw_sweep_lines(grid_rect)
	_draw_notes(grid_rect, cell_size)
	_draw_cursor(grid_rect, cell_size)


func _grid_rect() -> Rect2:
	var margin := Vector2.ONE * Config.GRID_MARGIN
	var view_size := get_viewport_rect().size
	return Rect2(margin, view_size - margin * 2.0)


func _cell_rect(grid_rect: Rect2, cell_size: Vector2, step: int, row: int) -> Rect2:
	return Rect2(grid_rect.position + Vector2(float(step), float(row)) * cell_size, cell_size)


func _draw_grid_lines(grid_rect: Rect2, cell_size: Vector2) -> void:
	for step: int in Config.STEPS + 1:
		var x := grid_rect.position.x + float(step) * cell_size.x
		draw_line(
			Vector2(x, grid_rect.position.y),
			Vector2(x, grid_rect.end.y),
			Config.GRID_LINE_COLOR,
			Config.GRID_LINE_WIDTH
		)
	for row: int in Config.ROWS + 1:
		var y := grid_rect.position.y + float(row) * cell_size.y
		draw_line(
			Vector2(grid_rect.position.x, y),
			Vector2(grid_rect.end.x, y),
			Config.GRID_LINE_COLOR,
			Config.GRID_LINE_WIDTH
		)


func _draw_sweep_lines(grid_rect: Rect2) -> void:
	# En la vista de todas las capas todas las líneas valen lo mismo.
	if state.show_all_layers:
		for layer: int in Config.LAYER_COUNT:
			_draw_sweep_line(layer, grid_rect, Config.SWEEP_LINE_WIDTH)
		return

	# Las inactivas primero y la activa al final, así la activa queda encima y más marcada.
	for layer: int in Config.LAYER_COUNT:
		if layer != state.active_layer_index:
			_draw_sweep_line(layer, grid_rect, Config.SWEEP_LINE_WIDTH)
	_draw_sweep_line(state.active_layer_index, grid_rect, Config.SWEEP_LINE_WIDTH_ACTIVE)


func _draw_sweep_line(layer: int, grid_rect: Rect2, line_width: float) -> void:
	var phase := sequencer.get_phase(layer)
	var x := grid_rect.position.x + phase / float(Config.STEPS) * grid_rect.size.x
	var line_color: Color = Config.LAYER_COLORS[layer]
	line_color.a = 0.85
	draw_line(
		Vector2(x, grid_rect.position.y),
		Vector2(x, grid_rect.end.y),
		line_color,
		line_width
	)


func _draw_notes(grid_rect: Rect2, cell_size: Vector2) -> void:
	if state.show_all_layers:
		_draw_all_layers_notes(grid_rect, cell_size)
		return
	var layer: int = state.active_layer_index
	var layer_color: Color = Config.LAYER_COLORS[layer]
	for cell: Vector2i in state.layers[layer].notes:
		draw_rect(_note_rect(grid_rect, cell_size, cell.x, cell.y), layer_color)


func _draw_all_layers_notes(grid_rect: Rect2, cell_size: Vector2) -> void:
	var layers_by_cell: Dictionary[Vector2i, Array] = {}
	for layer: int in Config.LAYER_COUNT:
		for cell: Vector2i in state.layers[layer].notes:
			if not layers_by_cell.has(cell):
				layers_by_cell[cell] = []
			var cell_layers: Array = layers_by_cell[cell]
			cell_layers.append(layer)
	for cell: Vector2i in layers_by_cell:
		_draw_shared_note(_note_rect(grid_rect, cell_size, cell.x, cell.y), layers_by_cell[cell])


# Si varias capas tienen nota en la misma celda, el cuadrado se parte en franjas horizontales,
# una por capa, en orden de capa. Con una sola capa queda el cuadrado entero.
func _draw_shared_note(note_rect: Rect2, layers: Array) -> void:
	var band_height := note_rect.size.y / float(layers.size())
	for index: int in layers.size():
		var band := Rect2(
			Vector2(note_rect.position.x, note_rect.position.y + band_height * float(index)),
			Vector2(note_rect.size.x, band_height)
		)
		var layer: int = layers[index]
		draw_rect(band, Config.LAYER_COLORS[layer])


func _note_rect(grid_rect: Rect2, cell_size: Vector2, step: int, row: int) -> Rect2:
	var note_size := cell_size * Config.NOTE_FILL_RATIO
	var inset := (cell_size - note_size) * 0.5
	var cell_rect := _cell_rect(grid_rect, cell_size, step, row)
	return Rect2(cell_rect.position + inset, note_size)


func _draw_cursor(grid_rect: Rect2, cell_size: Vector2) -> void:
	# Sin capa activa no hay cursor.
	if state.show_all_layers or not _cursor_visible():
		return
	var layer_color: Color = Config.LAYER_COLORS[state.active_layer_index]
	var cursor_rect := _cell_rect(grid_rect, cell_size, state.cursor_step, state.cursor_row)
	draw_rect(cursor_rect, layer_color, false, Config.CURSOR_OUTLINE_WIDTH)


func _cursor_visible() -> bool:
	var half_period_msec := Config.CURSOR_BLINK_PERIOD_MSEC / 2
	return Time.get_ticks_msec() % Config.CURSOR_BLINK_PERIOD_MSEC < half_period_msec
