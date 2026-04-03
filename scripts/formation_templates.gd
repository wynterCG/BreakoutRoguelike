class_name FormationTemplates

const TEMPLATE_NAMES: PackedStringArray = [
	"Full Grid", "Diamond", "V-Shape", "Walls", "Checkerboard",
	"Cross", "Scattered", "Corridor", "Pyramid", "Border",
	"Inverted V", "Zigzag", "Heart", "Spiral", "Arrows",
	"Clusters", "Diagonal Left", "Diagonal Right", "X-Shape", "Fortress",
	"Hourglass", "Teeth", "Ring", "Bullseye", "Staircase",
	"Waves", "Split Grid", "Dense Core", "Triple Line", "Random Heavy",
	"Double Diamond", "Hexagon", "Star", "Parallel Lines", "Grid Holes",
	"Crown", "Lightning", "Hashtag", "Bowtie", "Window",
	"Blob Left", "Blob Right", "Two Blobs", "Crescent", "Mushroom",
	"Amoeba", "Tree", "Skull", "Infinity", "Cloud",
	"Mirror V", "Concentric Sq", "Pinwheel", "DNA Helix", "Butterfly",
	"Snowflake", "Dominos", "Lattice", "Target", "Maze Walls",
	"Shield Wall", "Ambush", "Phalanx", "Scatter Guard", "Citadel",
	"Flanking", "Wedge", "Echelon", "Pocket", "Encircle",
	"Castle", "Bridge", "Tunnel", "Islands", "Columns",
	"Dam", "Skyline", "Tetris L", "Tetris T", "Barricade",
	"Quilt", "Sparse Diag", "Thick X", "Broken Grid", "Fence",
	"Ricochet", "Gauntlet", "Chessboard K", "Gradient", "Inv Gradient",
	"Plus Array", "Donut", "Arrow Up", "Three Rows", "Diagonal Fill",
	"Inv Diag Fill", "Center Line", "Sparse Ring", "Full Chaos", "The Gauntlet",
]


static func get_template_count() -> int:
	return TEMPLATE_NAMES.size()


static func get_template_name(index: int) -> String:
	if index >= 0 and index < TEMPLATE_NAMES.size():
		return TEMPLATE_NAMES[index]
	return "Unknown"


static func generate(index: int, columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = _generate_raw(index, columns, rows)
	return _deduplicate(cells)


static func _deduplicate(cells: Array[FormationCell]) -> Array[FormationCell]:
	var seen: Dictionary = {}
	var result: Array[FormationCell] = []
	for cell: FormationCell in cells:
		if not seen.has(cell.grid_position):
			seen[cell.grid_position] = true
			result.append(cell)
	return result


static func _generate_raw(index: int, columns: int, rows: int) -> Array[FormationCell]:
	match index:
		0: return _full_grid(columns, rows)
		1: return _diamond(columns, rows)
		2: return _v_shape(columns, rows)
		3: return _walls(columns, rows)
		4: return _checkerboard(columns, rows)
		5: return _cross(columns, rows)
		6: return _scattered(columns, rows, 42, 0.45)
		7: return _corridor(columns, rows)
		8: return _pyramid(columns, rows)
		9: return _border(columns, rows)
		10: return _inverted_v(columns, rows)
		11: return _zigzag(columns, rows)
		12: return _heart(columns, rows)
		13: return _spiral(columns, rows)
		14: return _arrows(columns, rows)
		15: return _clusters(columns, rows)
		16: return _diagonal_left(columns, rows)
		17: return _diagonal_right(columns, rows)
		18: return _x_shape(columns, rows)
		19: return _fortress(columns, rows)
		20: return _hourglass(columns, rows)
		21: return _teeth(columns, rows)
		22: return _ring(columns, rows)
		23: return _bullseye(columns, rows)
		24: return _staircase(columns, rows)
		25: return _waves(columns, rows)
		26: return _split_grid(columns, rows)
		27: return _dense_core(columns, rows)
		28: return _triple_line(columns, rows)
		29: return _scattered(columns, rows, 99, 0.65)
		30: return _double_diamond(columns, rows)
		31: return _hexagon(columns, rows)
		32: return _star(columns, rows)
		33: return _parallel_lines(columns, rows)
		34: return _grid_holes(columns, rows)
		35: return _crown(columns, rows)
		36: return _lightning(columns, rows)
		37: return _hashtag(columns, rows)
		38: return _bowtie(columns, rows)
		39: return _window(columns, rows)
		40: return _blob(columns, rows, 0.25)
		41: return _blob(columns, rows, 0.75)
		42: return _two_blobs(columns, rows)
		43: return _crescent(columns, rows)
		44: return _mushroom(columns, rows)
		45: return _scattered(columns, rows, 77, 0.5)
		46: return _tree(columns, rows)
		47: return _skull(columns, rows)
		48: return _infinity(columns, rows)
		49: return _cloud(columns, rows)
		50: return _mirror_v(columns, rows)
		51: return _concentric_sq(columns, rows)
		52: return _pinwheel(columns, rows)
		53: return _dna_helix(columns, rows)
		54: return _butterfly(columns, rows)
		55: return _snowflake(columns, rows)
		56: return _dominos(columns, rows)
		57: return _lattice(columns, rows)
		58: return _target(columns, rows)
		59: return _maze_walls(columns, rows)
		60: return _shield_wall(columns, rows)
		61: return _ambush(columns, rows)
		62: return _phalanx(columns, rows)
		63: return _scattered(columns, rows, 33, 0.35)
		64: return _citadel(columns, rows)
		65: return _flanking(columns, rows)
		66: return _wedge(columns, rows)
		67: return _echelon(columns, rows)
		68: return _pocket(columns, rows)
		69: return _encircle(columns, rows)
		70: return _castle(columns, rows)
		71: return _bridge(columns, rows)
		72: return _tunnel(columns, rows)
		73: return _islands(columns, rows)
		74: return _columns_pattern(columns, rows)
		75: return _dam(columns, rows)
		76: return _skyline(columns, rows)
		77: return _tetris_l(columns, rows)
		78: return _tetris_t(columns, rows)
		79: return _barricade(columns, rows)
		80: return _quilt(columns, rows)
		81: return _sparse_diag(columns, rows)
		82: return _thick_x(columns, rows)
		83: return _scattered(columns, rows, 22, 0.8)
		84: return _fence(columns, rows)
		85: return _ricochet(columns, rows)
		86: return _gauntlet(columns, rows)
		87: return _chessboard_k(columns, rows)
		88: return _gradient(columns, rows, true)
		89: return _gradient(columns, rows, false)
		90: return _plus_array(columns, rows)
		91: return _donut(columns, rows)
		92: return _arrow_up(columns, rows)
		93: return _three_rows(columns, rows)
		94: return _diagonal_fill(columns, rows, true)
		95: return _diagonal_fill(columns, rows, false)
		96: return _center_line(columns, rows)
		97: return _sparse_ring(columns, rows)
		98: return _scattered(columns, rows, 123, 0.55)
		99: return _gauntlet_full(columns, rows)
		_: return _full_grid(columns, rows)


# --- HELPERS ---

static func role_for_row(row: int, total_rows: int) -> StringName:
	var ratio: float = float(row) / float(total_rows)
	if ratio < 0.25:
		return &"support"
	if ratio < 0.55:
		return &"tank"
	return &"front"


static func _make_cell(col: int, row: int, total_rows: int) -> FormationCell:
	var cell: FormationCell = FormationCell.new()
	cell.grid_position = Vector2i(col, row)
	cell.role = role_for_row(row, total_rows)
	return cell


static func _in_bounds(col: int, row: int, columns: int, rows: int) -> bool:
	return col >= 0 and col < columns and row >= 0 and row < rows


static func _seeded_rand(seed_val: int, index: int) -> float:
	var s: int = (seed_val + index * 1103515245 + 12345) & 0x7FFFFFFF
	return float(s) / float(0x7FFFFFFF)


# --- PATTERN 0-9: BASICS ---

static func _full_grid(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			cells.append(_make_cell(c, r, rows))
	return cells


static func _diamond(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 2
	var cy: int = rows / 2
	var size_val: int = mini(cx, cy)
	for r: int in range(-size_val, size_val + 1):
		var width: int = size_val - absi(r)
		for c: int in range(-width, width + 1):
			if _in_bounds(cx + c, cy + r, columns, rows):
				cells.append(_make_cell(cx + c, cy + r, rows))
	return cells


static func _v_shape(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(mini(rows, 6)):
		if _in_bounds(r, r, columns, rows):
			cells.append(_make_cell(r, r, rows))
		if _in_bounds(columns - 1 - r, r, columns, rows):
			cells.append(_make_cell(columns - 1 - r, r, rows))
	return cells


static func _walls(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(mini(3, columns / 2)):
			cells.append(_make_cell(c, r, rows))
			if _in_bounds(columns - 1 - c, r, columns, rows):
				cells.append(_make_cell(columns - 1 - c, r, rows))
	return cells


static func _checkerboard(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if (r + c) % 2 == 0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _cross(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 2
	var cy: int = rows / 2
	for r: int in range(rows):
		cells.append(_make_cell(cx, r, rows))
		if cx > 0:
			cells.append(_make_cell(cx - 1, r, rows))
	for c: int in range(columns):
		if absi(c - cx) > 1:
			cells.append(_make_cell(c, cy, rows))
	return cells


static func _scattered(columns: int, rows: int, seed_val: int, density: float) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var idx: int = 0
	for r: int in range(rows):
		for c: int in range(columns):
			if _seeded_rand(seed_val, idx) < density:
				cells.append(_make_cell(c, r, rows))
			idx += 1
	return cells


static func _corridor(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		if r % 2 == 0:
			for c: int in range(columns):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _pyramid(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var max_rows: int = mini(rows, 7)
	for r: int in range(max_rows):
		var width: int = r + 1
		var start: int = (columns - width) / 2
		for c: int in range(width):
			if _in_bounds(start + c, max_rows - 1 - r, columns, rows):
				cells.append(_make_cell(start + c, max_rows - 1 - r, rows))
	return cells


static func _border(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var r_count: int = mini(rows, 6)
	for r: int in range(r_count):
		for c: int in range(columns):
			if r == 0 or r == r_count - 1 or c == 0 or c == columns - 1:
				cells.append(_make_cell(c, r, rows))
	return cells


# --- PATTERN 10-19 ---

static func _inverted_v(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 2
	for r: int in range(mini(rows, 6)):
		if _in_bounds(cx - r, r, columns, rows):
			cells.append(_make_cell(cx - r, r, rows))
		if _in_bounds(cx + r, r, columns, rows) and r > 0:
			cells.append(_make_cell(cx + r, r, rows))
	return cells


static func _zigzag(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(mini(rows, 6)):
		var off: int = (r % 2) * 3
		for c: int in range(off, mini(off + 8, columns)):
			cells.append(_make_cell(c, r, rows))
	return cells


static func _heart(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var pattern: Array[Array] = [
		[4, 5, 8, 9], [3, 4, 5, 6, 7, 8, 9, 10],
		[2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [3, 4, 5, 6, 7, 8, 9, 10],
		[4, 5, 6, 7, 8, 9], [5, 6, 7, 8], [6, 7],
	]
	for r: int in range(mini(pattern.size(), rows)):
		for c_val: Variant in pattern[r]:
			var c: int = c_val as int
			if _in_bounds(c, r, columns, rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _spiral(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var visited: Dictionary = {}
	var r: int = 0
	var c: int = 0
	var dr: int = 0
	var dc: int = 1
	var count: int = 0
	var max_count: int = int(columns * rows * 0.6)
	while count < max_count:
		if _in_bounds(c, r, columns, rows) and not visited.has(Vector2i(c, r)):
			visited[Vector2i(c, r)] = true
			cells.append(_make_cell(c, r, rows))
			count += 1
		var nr: int = r + dr
		var nc: int = c + dc
		if not _in_bounds(nc, nr, columns, rows) or visited.has(Vector2i(nc, nr)):
			var temp: int = dr
			dr = dc
			dc = -temp
		r += dr
		c += dc
		if not _in_bounds(c, r, columns, rows):
			break
	return cells


static func _arrows(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(mini(rows, 5)):
		if _in_bounds(3 + r, r, columns, rows):
			cells.append(_make_cell(3 + r, r, rows))
		if _in_bounds(3, r, columns, rows):
			cells.append(_make_cell(3, r, rows))
		if _in_bounds(mini(10, columns - 1) - r, r, columns, rows):
			cells.append(_make_cell(mini(10, columns - 1) - r, r, rows))
		if _in_bounds(mini(10, columns - 1), r, columns, rows):
			cells.append(_make_cell(mini(10, columns - 1), r, rows))
	return cells


static func _clusters(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var centers: Array[Vector2i] = [Vector2i(2, 1), Vector2i(columns / 2, rows / 2), Vector2i(columns - 3, 1)]
	for center: Vector2i in centers:
		for dr: int in range(-1, 2):
			for dc: int in range(-1, 2):
				if _in_bounds(center.x + dc, center.y + dr, columns, rows):
					cells.append(_make_cell(center.x + dc, center.y + dr, rows))
	return cells


static func _diagonal_left(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if absf(float(r) - float(c) * float(rows) / float(columns)) < 1.2:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _diagonal_right(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if absf(float(r) - float(columns - 1 - c) * float(rows) / float(columns)) < 1.2:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _x_shape(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			var d1: float = absf(float(r) / float(rows) - float(c) / float(columns))
			var d2: float = absf(float(r) / float(rows) - float(columns - 1 - c) / float(columns))
			if d1 < 0.15 or d2 < 0.15:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _fortress(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var r_count: int = mini(rows, 6)
	for r: int in range(r_count):
		for c: int in range(columns):
			if r == 0 or r == r_count - 1 or c == 0 or c == columns - 1:
				cells.append(_make_cell(c, r, rows))
			elif r >= 2 and r <= 3 and c >= columns / 2 - 2 and c <= columns / 2 + 1:
				cells.append(_make_cell(c, r, rows))
	return cells


# --- PATTERN 20-29 ---

static func _hourglass(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cy: int = rows / 2
	for r: int in range(rows):
		var dist: float = absf(float(r - cy)) / float(cy) if cy > 0 else 0.0
		var width: int = maxi(2, int(float(columns) * (0.3 + 0.7 * dist)))
		var start: int = (columns - width) / 2
		for c: int in range(start, start + width):
			if _in_bounds(c, r, columns, rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _teeth(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for c: int in range(columns):
		if c % 3 == 0:
			for r: int in range(mini(4, rows)):
				cells.append(_make_cell(c, r, rows))
		elif c % 3 == 1:
			for r: int in range(maxi(0, rows - 4), rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _ring(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / (cx * 0.9)) ** 2 + ((float(r) - cy) / (cy * 0.9)) ** 2
			if d > 0.5 and d < 1.3:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _bullseye(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / (cx * 0.9)) ** 2 + ((float(r) - cy) / (cy * 0.9)) ** 2
			if (d > 0.15 and d < 0.4) or (d > 0.7 and d < 1.1):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _staircase(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var steps: int = mini(5, rows)
	var step_width: int = maxi(2, columns / steps)
	for s: int in range(steps):
		for c: int in range(s * step_width, mini((s + 1) * step_width, columns)):
			cells.append(_make_cell(c, s, rows))
			if _in_bounds(c, s + 1, columns, rows):
				cells.append(_make_cell(c, s + 1, rows))
	return cells


static func _waves(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for wave: int in range(mini(3, rows / 2)):
		for c: int in range(columns):
			var y: int = clampi(int(roundf(float(wave) * 2.5 + sin(float(c) * 0.7) * 1.2)), 0, rows - 1)
			cells.append(_make_cell(c, y, rows))
	return cells


static func _split_grid(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var gap_start: int = columns / 2 - 2
	var gap_end: int = columns / 2 + 1
	for r: int in range(mini(rows, 5)):
		for c: int in range(columns):
			if c < gap_start or c > gap_end:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _dense_core(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var dist: float = absf(float(c) - cx) / float(columns) + absf(float(r) - cy) / float(rows)
			if dist < 0.3:
				cells.append(_make_cell(c, r, rows))
			elif dist < 0.5 and (r + c) % 3 == 0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _triple_line(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var lines: Array[int] = [0, rows / 2, rows - 1]
	for r: int in lines:
		if r >= 0 and r < rows:
			for c: int in range(1, columns - 1):
				cells.append(_make_cell(c, r, rows))
	return cells


# --- PATTERN 30-39: GEOMETRIC ---

static func _double_diamond(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var centers: Array[int] = [columns / 3, columns * 2 / 3]
	var cy: int = rows / 2
	var size_val: int = mini(columns / 6, cy)
	for cx: int in centers:
		for r: int in range(-size_val, size_val + 1):
			var width: int = size_val - absi(r)
			for c: int in range(-width, width + 1):
				if _in_bounds(cx + c, cy + r, columns, rows):
					cells.append(_make_cell(cx + c, cy + r, rows))
	return cells


static func _hexagon(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var dx: float = absf(float(c) - cx) / (cx * 0.8)
			var dy: float = absf(float(r) - cy) / (cy * 0.85)
			if dx + dy * 0.6 < 1.0 and dy < 1.0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _star(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var dx: float = float(c) - cx
			var dy: float = float(r) - cy
			var a: float = atan2(dy, dx / 2.0)
			var d: float = sqrt((dx / float(columns) * 2.0) ** 2 + (dy / float(rows) * 2.0) ** 2)
			var star_r: float = 0.5 + 0.3 * cos(a * 3.0)
			if d < star_r:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _parallel_lines(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if c % 3 == 0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _grid_holes(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(mini(rows, 5)):
		for c: int in range(columns):
			if not ((r == 1 or r == 3) and (c == columns / 4 or c == columns / 2 or c == columns * 3 / 4)):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _crown(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for c: int in range(columns):
		for r: int in range(maxi(0, rows - 2), rows):
			cells.append(_make_cell(c, r, rows))
		if c % 3 == 0:
			for r: int in range(rows - 2):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _lightning(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 4
	for r: int in range(mini(rows, 7)):
		var offset: int = cx + (r % 2) * 2
		if _in_bounds(offset, r, columns, rows):
			cells.append(_make_cell(offset, r, rows))
		if _in_bounds(offset + 1, r, columns, rows):
			cells.append(_make_cell(offset + 1, r, rows))
	return cells


static func _hashtag(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var c1: int = columns / 3
	var c2: int = columns * 2 / 3
	var r1: int = rows / 3
	var r2: int = rows * 2 / 3
	for r: int in range(rows):
		if r == r1 or r == r2:
			for c: int in range(1, columns - 1):
				cells.append(_make_cell(c, r, rows))
		cells.append(_make_cell(c1, r, rows))
		cells.append(_make_cell(c2, r, rows))
	return cells


static func _bowtie(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cy: int = rows / 2
	for r: int in range(rows):
		var w1: int = absi(r - cy)
		var w2: int = cy - absi(r - cy)
		for c: int in range(mini(w1 + 1, columns / 2)):
			cells.append(_make_cell(c, r, rows))
		for c: int in range(maxi(columns - 1 - w2, columns / 2), columns):
			if _in_bounds(c, r, columns, rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _window(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var r_count: int = mini(rows, 6)
	var cx: int = columns / 2
	var cy: int = r_count / 2
	for r: int in range(r_count):
		for c: int in range(columns):
			if r == 0 or r == r_count - 1 or r == cy or r == cy - 1 or c == 0 or c == columns - 1 or c == cx or c == cx - 1:
				cells.append(_make_cell(c, r, rows))
	return cells


# --- PATTERN 40-49: ORGANIC ---

static func _blob(columns: int, rows: int, x_ratio: float) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) * x_ratio
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / 4.0) ** 2 + ((float(r) - cy) / 3.0) ** 2
			if d < 1.0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _two_blobs(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx1: float = float(columns) * 0.25
	var cx2: float = float(columns) * 0.75
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d1: float = ((float(c) - cx1) / 3.0) ** 2 + ((float(r) - cy) / 2.5) ** 2
			var d2: float = ((float(c) - cx2) / 3.0) ** 2 + ((float(r) - cy) / 2.5) ** 2
			if d1 < 1.0 or d2 < 1.0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _crescent(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d1: float = ((float(c) - cx) / 5.0) ** 2 + ((float(r) - cy) / 3.0) ** 2
			var d2: float = ((float(c) - cx + 2.0) / 4.0) ** 2 + ((float(r) - cy + 0.5) / 2.5) ** 2
			if d1 < 1.0 and d2 >= 1.0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _mushroom(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / 5.0) ** 2 + ((float(r) - 2.0) / 2.0) ** 2
			if d < 1.0:
				cells.append(_make_cell(c, r, rows))
			elif r >= rows - 3 and absi(c - int(cx)) <= 1:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _tree(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 2
	for r: int in range(mini(4, rows)):
		var width: int = maxi(1, 4 - r)
		var start: int = cx - width
		for c: int in range(start, mini(start + width * 2, columns)):
			if _in_bounds(c, r, columns, rows):
				cells.append(_make_cell(c, r, rows))
	for r: int in range(4, rows):
		if _in_bounds(cx, r, columns, rows):
			cells.append(_make_cell(cx, r, rows))
		if _in_bounds(cx - 1, r, columns, rows):
			cells.append(_make_cell(cx - 1, r, rows))
	return cells


static func _skull(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / 5.0) ** 2 + ((float(r) - 2.5) / 3.0) ** 2
			if d < 0.9:
				if r >= 1 and r <= 3 and ((c >= int(cx) - 3 and c <= int(cx) - 2) or (c >= int(cx) + 1 and c <= int(cx) + 2)):
					continue
				cells.append(_make_cell(c, r, rows))
	return cells


static func _infinity(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx1: float = float(columns) * 0.3
	var cx2: float = float(columns) * 0.7
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d1: float = ((float(c) - cx1) / 3.0) ** 2 + ((float(r) - cy) / 2.5) ** 2
			var d2: float = ((float(c) - cx2) / 3.0) ** 2 + ((float(r) - cy) / 2.5) ** 2
			if (d1 > 0.3 and d1 < 1.0) or (d2 > 0.3 and d2 < 1.0):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _cloud(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var centers: Array[Array] = [[float(columns) * 0.3, 2.0, 3.5], [float(columns) * 0.6, 2.5, 4.0], [float(columns) * 0.8, 3.0, 3.0]]
	for r: int in range(rows):
		for c: int in range(columns):
			for center: Array in centers:
				var d: float = ((float(c) - center[0]) / center[2]) ** 2 + ((float(r) - center[1]) / 2.0) ** 2
				if d < 1.0:
					cells.append(_make_cell(c, r, rows))
					break
	return cells


# --- PATTERN 50-59: SYMMETRICAL ---

static func _mirror_v(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(mini(rows, 5)):
		for offset: int in [r, columns / 2 - r - 1, columns / 2 + r, columns - 1 - r]:
			if _in_bounds(offset, r, columns, rows):
				cells.append(_make_cell(offset, r, rows))
	return cells


static func _concentric_sq(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for s: int in range(3):
		var min_c: int = s * 2
		var max_c: int = columns - 1 - s * 2
		var min_r: int = s
		var max_r: int = mini(rows - 1, 5) - s
		if min_c >= max_c or min_r >= max_r:
			break
		for c: int in range(min_c, max_c + 1):
			cells.append(_make_cell(c, min_r, rows))
			cells.append(_make_cell(c, max_r, rows))
		for r: int in range(min_r + 1, max_r):
			cells.append(_make_cell(min_c, r, rows))
			cells.append(_make_cell(max_c, r, rows))
	return cells


static func _pinwheel(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var dx: float = float(c) - cx
			var dy: float = float(r) - cy
			var a: float = (atan2(dy, dx) + PI) / (2.0 * PI)
			var d: float = sqrt(dx * dx + dy * dy)
			if d < mini(columns, rows) * 0.45 and fmod(a * 4.0 + d * 0.1, 1.0) < 0.5:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _dna_helix(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 2
	for r: int in range(rows):
		var x1: int = clampi(cx + int(roundf(sin(float(r) * 1.2) * 4.0)), 0, columns - 1)
		var x2: int = clampi(cx - int(roundf(sin(float(r) * 1.2) * 4.0)), 0, columns - 1)
		cells.append(_make_cell(x1, r, rows))
		cells.append(_make_cell(x2, r, rows))
		if r % 2 == 0:
			for c: int in range(mini(x1, x2), maxi(x1, x2) + 1):
				if _in_bounds(c, r, columns, rows):
					cells.append(_make_cell(c, r, rows))
	return cells


static func _butterfly(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var dx: float = absf(float(c) - cx)
			var dy: float = absf(float(r) - cy)
			if dx > 0.5 and dx < 5.0 + sin(dy * 1.5) * 2.0 and dy < cy:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _snowflake(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var dx: float = float(c) - cx
			var dy: float = float(r) - cy
			var a: float = atan2(dy, dx / 2.0)
			var d: float = sqrt((dx / float(columns) * 2.0) ** 2 + (dy / float(rows) * 2.0) ** 2)
			if d < 0.8 and (cos(a * 3.0) > 0.0 or d < 0.3):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _dominos(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var idx: int = 0
	for r: int in range(0, rows - 1, 2):
		for c: int in range(0, columns, 3):
			if _seeded_rand(55, idx) < 0.7:
				cells.append(_make_cell(c, r, rows))
				if _in_bounds(c, r + 1, columns, rows):
					cells.append(_make_cell(c, r + 1, rows))
			idx += 1
	return cells


static func _lattice(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if (r + c) % 3 == 0 or (r - c + columns) % 3 == 0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _target(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / (cx * 0.9)) ** 2 + ((float(r) - cy) / (cy * 0.9)) ** 2
			if d > 0.6 and d < 1.0:
				cells.append(_make_cell(c, r, rows))
			elif c == int(cx) or c == int(cx) - 1 or r == int(cy):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _maze_walls(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if r == 0 or r == rows - 1:
				cells.append(_make_cell(c, r, rows))
			elif r == 2 and c > 2:
				cells.append(_make_cell(c, r, rows))
			elif r == 4 and c < columns - 3:
				cells.append(_make_cell(c, r, rows))
			elif c == 0 or c == columns - 1:
				cells.append(_make_cell(c, r, rows))
	return cells


# --- PATTERN 60-69: TACTICAL ---

static func _shield_wall(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(maxi(0, rows - 3), rows):
		for c: int in range(columns):
			cells.append(_make_cell(c, r, rows))
	for r: int in range(maxi(0, rows - 3)):
		for c: int in range(0, columns, 4):
			if _in_bounds(c, r, columns, rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _ambush(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(mini(3, rows)):
		for c: int in range(mini(4, columns / 2)):
			cells.append(_make_cell(c, r, rows))
			if _in_bounds(columns - 1 - c, r, columns, rows):
				cells.append(_make_cell(columns - 1 - c, r, rows))
	var cx: int = columns / 2
	for r: int in range(rows / 2, rows):
		if _in_bounds(cx, r, columns, rows):
			cells.append(_make_cell(cx, r, rows))
		if _in_bounds(cx - 1, r, columns, rows):
			cells.append(_make_cell(cx - 1, r, rows))
	return cells


static func _phalanx(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var start: int = columns / 4
	var end_col: int = columns * 3 / 4
	for r: int in range(rows):
		for c: int in range(start, end_col):
			cells.append(_make_cell(c, r, rows))
	return cells


static func _citadel(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			var layer: int = mini(mini(r, rows - 1 - r), mini(c / 2, (columns - 1 - c) / 2))
			if layer <= 2:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _flanking(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		if r < rows / 2:
			for c: int in range(mini(3, columns)):
				cells.append(_make_cell(c, r, rows))
			for c: int in range(maxi(0, columns - 3), columns):
				cells.append(_make_cell(c, r, rows))
		else:
			for c: int in range(3, columns - 3):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _wedge(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cy: int = rows / 2
	for r: int in range(rows):
		var width: int = maxi(1, 4 - absi(r - cy))
		for c: int in range(width):
			if _in_bounds(c, r, columns, rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _echelon(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		var start: int = r * 2
		for c: int in range(start, mini(start + 4, columns)):
			cells.append(_make_cell(c, r, rows))
	return cells


static func _pocket(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		cells.append(_make_cell(0, r, rows))
		if columns > 1:
			cells.append(_make_cell(1, r, rows))
		cells.append(_make_cell(columns - 1, r, rows))
		if columns > 1:
			cells.append(_make_cell(columns - 2, r, rows))
		if r >= rows - 3:
			for c: int in range(2, columns - 2):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _encircle(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / (cx * 0.95)) ** 2 + ((float(r) - cy) / (cy * 0.95)) ** 2
			if d > 0.4 and d < 1.0 and r > 0:
				cells.append(_make_cell(c, r, rows))
	return cells


# --- PATTERN 70-79: THEMED ---

static func _castle(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for c: int in range(columns):
		for r: int in range(maxi(0, rows - 2), rows):
			cells.append(_make_cell(c, r, rows))
		if c % 2 == 0:
			for r: int in range(maxi(0, rows - 4), rows - 2):
				cells.append(_make_cell(c, r, rows))
		if c == 0 or c == columns - 1 or c == columns / 2 or c == columns / 2 - 1:
			for r: int in range(rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _bridge(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for c: int in range(columns):
		var arch_h: int = int(roundf(3.0 - 2.0 * cos(float(c) / float(columns - 1) * PI)))
		for r: int in range(arch_h, rows):
			if _in_bounds(c, r, columns, rows):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _tunnel(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if r <= 1 or r >= rows - 2 or c <= 1 or c >= columns - 2:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _islands(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var positions: Array[Vector2i] = [
		Vector2i(2, 1), Vector2i(columns / 2, 1),
		Vector2i(columns - 3, 1), Vector2i(columns / 3, rows - 2),
		Vector2i(columns * 2 / 3, rows - 2),
	]
	for pos: Vector2i in positions:
		for dr: int in range(-1, 2):
			for dc: int in range(-1, 2):
				if absi(dr) + absi(dc) <= 1 and _in_bounds(pos.x + dc, pos.y + dr, columns, rows):
					cells.append(_make_cell(pos.x + dc, pos.y + dr, rows))
	return cells


static func _columns_pattern(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for c: int in range(1, columns, 3):
		for r: int in range(rows):
			cells.append(_make_cell(c, r, rows))
	return cells


static func _dam(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 2
	for r: int in range(mini(3, rows)):
		for c: int in range(columns):
			if not (r == 1 and c >= cx - 1 and c <= cx):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _skyline(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var idx: int = 0
	for c: int in range(columns):
		var height: int = clampi(int(3.0 + _seeded_rand(88, idx) * 4.0), 2, rows)
		for r: int in range(rows - height, rows):
			cells.append(_make_cell(c, r, rows))
		idx += 1
	return cells


static func _tetris_l(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var spacing: int = maxi(3, columns / 4)
	for start_c: int in range(0, columns - 1, spacing):
		var start_r: int = clampi(int(_seeded_rand(44, start_c) * 2.0), 0, maxi(0, rows - 3))
		for r: int in range(start_r, mini(start_r + 3, rows)):
			if _in_bounds(start_c, r, columns, rows):
				cells.append(_make_cell(start_c, r, rows))
		if _in_bounds(start_c + 1, mini(start_r + 2, rows - 1), columns, rows):
			cells.append(_make_cell(start_c + 1, mini(start_r + 2, rows - 1), rows))
	return cells


static func _tetris_t(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var spacing: int = maxi(4, columns / 3)
	for start_c: int in range(1, columns - 2, spacing):
		var r: int = clampi(int(_seeded_rand(66, start_c) * 3.0), 0, maxi(0, rows - 2))
		for c: int in range(start_c, mini(start_c + 3, columns)):
			cells.append(_make_cell(c, r, rows))
		if _in_bounds(start_c + 1, r + 1, columns, rows):
			cells.append(_make_cell(start_c + 1, r + 1, rows))
	return cells


static func _barricade(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(mini(4, rows)):
		for c: int in range(columns):
			cells.append(_make_cell(c, r, rows))
	return cells


# --- PATTERN 80-89 ---

static func _quilt(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var idx: int = 0
	for br: int in range(0, rows - 1, 2):
		for bc: int in range(0, columns - 2, 3):
			if _seeded_rand(11, idx) < 0.7:
				for r: int in range(br, mini(br + 2, rows)):
					for c: int in range(bc, mini(bc + 3, columns)):
						cells.append(_make_cell(c, r, rows))
			idx += 1
	return cells


static func _sparse_diag(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if (r + c) % 4 == 0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _thick_x(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			var d1: float = absf(float(r) / float(rows) - float(c) / float(columns))
			var d2: float = absf(float(r) / float(rows) - float(columns - 1 - c) / float(columns))
			if d1 < 0.15 or d2 < 0.15:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _fence(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var r1: int = rows / 3
	var r2: int = rows * 2 / 3
	for c: int in range(columns):
		if c % 4 == 0:
			for r: int in range(rows):
				cells.append(_make_cell(c, r, rows))
		if _in_bounds(c, r1, columns, rows):
			cells.append(_make_cell(c, r1, rows))
		if _in_bounds(c, r2, columns, rows):
			cells.append(_make_cell(c, r2, rows))
	return cells


static func _ricochet(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for i: int in range(mini(rows, 7)):
		if _in_bounds(i, i, columns, rows):
			cells.append(_make_cell(i, i, rows))
		if _in_bounds(i + 1, i, columns, rows):
			cells.append(_make_cell(i + 1, i, rows))
		var c2: int = mini(i + 7, columns - 1)
		if _in_bounds(c2, rows - 1 - i, columns, rows):
			cells.append(_make_cell(c2, rows - 1 - i, rows))
		if _in_bounds(c2 + 1, rows - 1 - i, columns, rows):
			cells.append(_make_cell(c2 + 1, rows - 1 - i, rows))
	return cells


static func _gauntlet(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if c < columns / 3 or c > columns * 2 / 3 or r == 0 or r == rows - 1:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _chessboard_k(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if (r * columns + c) % 5 < 2:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _gradient(columns: int, rows: int, top_heavy: bool) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var idx: int = 0
	for r: int in range(rows):
		for c: int in range(columns):
			var density: float = 1.0 - float(r) * 0.12 if top_heavy else 0.2 + float(r) * 0.12
			if _seeded_rand(44, idx) < density:
				cells.append(_make_cell(c, r, rows))
			idx += 1
	return cells


# --- PATTERN 90-99 ---

static func _plus_array(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for br: int in range(0, rows - 2, 3):
		for bc: int in range(0, columns - 2, 4):
			var cr: int = br + 1
			var cc: int = bc + 2
			if _in_bounds(cc, cr, columns, rows):
				cells.append(_make_cell(cc, cr, rows))
			if _in_bounds(cc, cr - 1, columns, rows):
				cells.append(_make_cell(cc, cr - 1, rows))
			if _in_bounds(cc, cr + 1, columns, rows):
				cells.append(_make_cell(cc, cr + 1, rows))
			if _in_bounds(cc - 1, cr, columns, rows):
				cells.append(_make_cell(cc - 1, cr, rows))
			if _in_bounds(cc + 1, cr, columns, rows):
				cells.append(_make_cell(cc + 1, cr, rows))
	return cells


static func _donut(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / (cx * 0.9)) ** 2 + ((float(r) - cy) / (cy * 0.9)) ** 2
			if d < 1.0 and d > 0.2:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _arrow_up(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: int = columns / 2
	for r: int in range(rows):
		if r < rows / 2:
			var width: int = maxi(0, rows / 2 - r)
			for c: int in range(cx - width, cx + width + 1):
				if _in_bounds(c, r, columns, rows):
					cells.append(_make_cell(c, r, rows))
		else:
			for c: int in range(cx - 2, cx + 3):
				if _in_bounds(c, r, columns, rows):
					cells.append(_make_cell(c, r, rows))
	return cells


static func _three_rows(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var row_positions: Array[int] = [0, rows / 2, rows - 1]
	for r: int in row_positions:
		if r >= 0 and r < rows:
			for c: int in range(2, columns - 2):
				cells.append(_make_cell(c, r, rows))
	return cells


static func _diagonal_fill(columns: int, rows: int, left_to_right: bool) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	for r: int in range(rows):
		for c: int in range(columns):
			if left_to_right:
				if c < r * 2 + 1:
					cells.append(_make_cell(c, r, rows))
			else:
				if c >= columns - r * 2 - 1:
					cells.append(_make_cell(c, r, rows))
	return cells


static func _center_line(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var start_r: int = rows / 2 - 1
	for r: int in range(start_r, mini(start_r + 3, rows)):
		for c: int in range(columns):
			cells.append(_make_cell(c, r, rows))
	return cells


static func _sparse_ring(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx: float = float(columns) / 2.0
	var cy: float = float(rows) / 2.0
	for r: int in range(rows):
		for c: int in range(columns):
			var d: float = ((float(c) - cx) / (cx * 0.9)) ** 2 + ((float(r) - cy) / (cy * 0.9)) ** 2
			if d > 0.6 and d < 1.1 and (r + c) % 2 == 0:
				cells.append(_make_cell(c, r, rows))
	return cells


static func _gauntlet_full(columns: int, rows: int) -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	var cx_start: int = columns / 2 - 2
	var cx_end: int = columns / 2 + 1
	for r: int in range(rows):
		for c: int in range(columns):
			if not (r >= rows / 3 and r <= rows * 2 / 3 and c >= cx_start and c <= cx_end):
				cells.append(_make_cell(c, r, rows))
	return cells
