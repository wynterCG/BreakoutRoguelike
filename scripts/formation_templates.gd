class_name FormationTemplates

const TEMPLATE_NAMES: PackedStringArray = [
	# Category 1: Introduction (0-7)
	"Trio", "Five Spread", "Big Center", "Diamond", "Pyramid",
	"Wings", "Arch", "Scatter Ring",
	# Category 2: Tank Walls (8-14)
	"Shield Line", "Big Guard", "Twin Shields", "Bunker", "Pillars",
	"Gate", "Barricade",
	# Category 3: Support (15-21)
	"Orbiting Pair", "Protected Orbiters", "Flankers", "Constellation",
	"Zigzag Field", "Ring Guard", "Layered Defense",
	# Category 4: Elite Encounters (22-28)
	"Boss Center", "Charge Lane", "Twin Bosses", "Fortress",
	"Gauntlet", "Pincer", "Dragon's Nest",
	# Category 5: Mixed Chaos (29-34)
	"Full Mix", "Moving Maze", "Siege", "Storm", "Final Stand",
	"Dragon Lair",
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


static func _generate_raw(index: int, _columns: int, _rows: int) -> Array[FormationCell]:
	match index:
		0: return _t00_trio()
		1: return _t01_five_spread()
		2: return _t02_big_center()
		3: return _t03_diamond()
		4: return _t04_pyramid()
		5: return _t05_wings()
		6: return _t06_arch()
		7: return _t07_scatter_ring()
		8: return _t08_shield_line()
		9: return _t09_big_guard()
		10: return _t10_twin_shields()
		11: return _t11_bunker()
		12: return _t12_pillars()
		13: return _t13_gate()
		14: return _t14_barricade()
		15: return _t15_orbiting_pair()
		16: return _t16_protected_orbiters()
		17: return _t17_flankers()
		18: return _t18_constellation()
		19: return _t19_zigzag_field()
		20: return _t20_ring_guard()
		21: return _t21_layered_defense()
		22: return _t22_boss_center()
		23: return _t23_charge_lane()
		24: return _t24_twin_bosses()
		25: return _t25_fortress()
		26: return _t26_gauntlet()
		27: return _t27_pincer()
		28: return _t28_dragons_nest()
		29: return _t29_full_mix()
		30: return _t30_moving_maze()
		31: return _t31_siege()
		32: return _t32_storm()
		33: return _t33_final_stand()
		34: return _t34_dragon_lair()
	return []


# --- HELPERS ---
# 15-column grid: center = col 7, mirror = 14 - x

static func role_for_row(row: int, total_rows: int) -> StringName:
	var ratio: float = float(row) / float(total_rows)
	if ratio < 0.25:
		return &"support"
	if ratio < 0.55:
		return &"tank"
	return &"front"


static func _cell(col: int, row: int, role: StringName, sx: float = 1.0, sy: float = 1.0) -> FormationCell:
	var c: FormationCell = FormationCell.new()
	c.grid_position = Vector2i(col, row)
	c.role = role
	if sx != 1.0 or sy != 1.0:
		c.size_scale = Vector2(sx, sy)
	return c


# Symmetric pair: place at x and mirror at (14 - x) for 15-col grid
static func _sym(x: int, y: int, role: StringName, sx: float = 1.0, sy: float = 1.0) -> Array[FormationCell]:
	var mx: int = 14 - x
	if mx == x:
		return [_cell(x, y, role, sx, sy)]
	return [_cell(x, y, role, sx, sy), _cell(mx, y, role, sx, sy)]


# Center cell at column 7
static func _mid(y: int, role: StringName, sx: float = 1.0, sy: float = 1.0) -> Array[FormationCell]:
	return [_cell(7, y, role, sx, sy)]


# --- CATEGORY 1: Introduction (Front only) ---

static func _t00_trio() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(0, &"front", 2.0, 1.5))
	cells.append_array(_sym(4, 1, &"front"))
	return cells


static func _t01_five_spread() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"front"))
	cells.append_array(_mid(0, &"front"))
	cells.append_array(_sym(5, 2, &"front"))
	return cells


static func _t02_big_center() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(0, &"tank", 3.0, 2.0))
	cells.append_array(_sym(2, 2, &"front"))
	cells.append_array(_sym(4, 2, &"support"))
	return cells


static func _t03_diamond() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(0, &"front", 1.5, 1.0))
	cells.append_array(_sym(5, 1, &"front", 1.5, 1.0))
	cells.append_array(_sym(4, 2, &"front", 1.5, 1.0))
	cells.append_array(_mid(3, &"front", 1.5, 1.0))
	return cells


static func _t04_pyramid() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(0, &"elite", 2.0, 1.5))
	cells.append_array(_sym(5, 1, &"support", 1.5, 1.0))
	cells.append_array(_sym(4, 2, &"tank"))
	cells.append_array(_sym(3, 3, &"front"))
	cells.append_array(_sym(5, 3, &"front"))
	cells.append_array(_mid(3, &"front"))
	return cells


static func _t05_wings() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(0, &"support", 2.0, 1.5))
	cells.append_array(_sym(4, 0, &"tank", 1.5, 1.0))
	cells.append_array(_sym(2, 1, &"front", 2.0, 1.0))
	cells.append_array(_sym(1, 2, &"front", 1.5, 1.5))
	return cells


static func _t06_arch() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(5, 0, &"support", 1.5, 1.0))
	cells.append_array(_sym(3, 1, &"tank", 1.5, 1.5))
	cells.append_array(_sym(2, 2, &"front", 1.5, 1.5))
	cells.append_array(_sym(4, 3, &"front"))
	cells.append_array(_mid(3, &"elite", 2.0, 1.0))
	return cells


static func _t07_scatter_ring() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(5, 0, &"support", 1.5, 1.0))
	cells.append_array(_sym(3, 1, &"tank"))
	cells.append_array(_sym(5, 1, &"front"))
	cells.append_array(_sym(3, 2, &"front"))
	cells.append_array(_sym(5, 2, &"front"))
	cells.append_array(_sym(5, 3, &"support", 1.5, 1.0))
	return cells


# --- CATEGORY 2: Tank Walls ---

static func _t08_shield_line() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"tank", 2.0, 1.5))
	cells.append_array(_mid(0, &"support", 2.0, 1.5))
	cells.append_array(_sym(4, 2, &"front"))
	cells.append_array(_sym(6, 2, &"front"))
	cells.append_array(_mid(3, &"elite", 1.5, 1.0))
	return cells


static func _t09_big_guard() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(0, &"tank", 3.0, 2.5))
	cells.append_array(_sym(2, 1, &"support"))
	cells.append_array(_sym(4, 1, &"front"))
	cells.append_array(_sym(3, 3, &"front", 1.5, 1.0))
	return cells


static func _t10_twin_shields() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"tank", 2.5, 2.0))
	cells.append_array(_sym(6, 2, &"support"))
	cells.append_array(_mid(2, &"elite", 2.0, 1.5))
	cells.append_array(_sym(5, 3, &"front"))
	return cells


static func _t11_bunker() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"tank", 1.5, 1.0))
	cells.append_array(_sym(3, 2, &"tank", 1.0, 1.5))
	cells.append_array(_sym(5, 4, &"front", 1.5, 1.0))
	cells.append_array(_mid(4, &"support", 1.5, 1.0))
	cells.append_array(_sym(5, 1, &"support", 1.5, 1.0))
	cells.append_array(_mid(2, &"elite", 2.0, 1.5))
	return cells


static func _t12_pillars() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"tank", 1.0, 3.0))
	cells.append_array(_mid(0, &"support", 1.0, 3.0))
	cells.append_array(_sym(1, 1, &"front", 1.5, 1.0))
	cells.append_array(_sym(5, 2, &"support"))
	cells.append_array(_sym(5, 3, &"front"))
	cells.append_array(_sym(1, 4, &"front"))
	return cells


static func _t13_gate() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(4, 0, &"tank", 1.0, 3.0))
	cells.append_array(_sym(5, 0, &"support", 1.5, 1.0))
	cells.append_array(_mid(1, &"elite", 2.0, 2.0))
	cells.append_array(_sym(6, 3, &"front"))
	cells.append_array(_mid(4, &"front", 1.5, 1.0))
	return cells


static func _t14_barricade() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(2, 0, &"tank", 2.5, 1.5))
	cells.append_array(_mid(0, &"support", 2.5, 1.5))
	cells.append_array(_sym(4, 2, &"front", 1.5, 1.0))
	cells.append_array(_mid(2, &"elite", 1.5, 1.0))
	return cells


# --- CATEGORY 3: Support Formations ---

static func _t15_orbiting_pair() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"support", 2.0, 1.5))
	cells.append_array(_mid(2, &"front", 2.0, 1.5))
	cells.append_array(_sym(5, 3, &"front"))
	cells.append_array(_sym(2, 4, &"front"))
	return cells


static func _t16_protected_orbiters() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"tank", 2.0, 1.5))
	cells.append_array(_mid(1, &"support", 2.5, 2.0))
	cells.append_array(_sym(4, 3, &"support", 1.5, 1.0))
	cells.append_array(_sym(2, 4, &"front"))
	cells.append_array(_mid(4, &"front"))
	return cells


static func _t17_flankers() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(1, 0, &"support", 1.5, 1.5))
	cells.append_array(_sym(1, 2, &"support", 1.5, 1.5))
	cells.append_array(_mid(0, &"tank", 2.0, 1.5))
	cells.append_array(_mid(2, &"front", 2.0, 1.0))
	cells.append_array(_sym(5, 3, &"front"))
	return cells


static func _t18_constellation() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(2, 0, &"support", 1.5, 1.5))
	cells.append_array(_sym(5, 0, &"support", 1.5, 1.5))
	cells.append_array(_mid(2, &"support", 2.5, 2.0))
	cells.append_array(_sym(3, 4, &"front"))
	cells.append_array(_sym(5, 4, &"front"))
	return cells


static func _t19_zigzag_field() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(2, 0, &"support", 1.5, 1.0))
	cells.append_array(_mid(0, &"support", 1.5, 1.0))
	cells.append_array(_sym(4, 1, &"support", 1.5, 1.5))
	cells.append_array(_sym(1, 3, &"support"))
	cells.append_array(_mid(4, &"front", 2.0, 1.0))
	cells.append_array(_sym(4, 4, &"front"))
	return cells


static func _t20_ring_guard() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(5, 0, &"support", 1.5, 1.0))
	cells.append_array(_sym(3, 1, &"support", 1.5, 1.0))
	cells.append_array(_sym(5, 1, &"support"))
	cells.append_array(_sym(3, 3, &"support", 1.5, 1.0))
	cells.append_array(_sym(5, 3, &"support"))
	cells.append_array(_sym(5, 4, &"support", 1.5, 1.0))
	cells.append_array(_mid(2, &"front", 2.0, 1.5))
	return cells


static func _t21_layered_defense() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"front"))
	cells.append_array(_sym(5, 0, &"front"))
	cells.append_array(_mid(0, &"front"))
	cells.append_array(_sym(3, 1, &"tank", 2.0, 1.5))
	cells.append_array(_mid(1, &"tank", 2.0, 1.5))
	cells.append_array(_sym(4, 3, &"support", 2.0, 1.5))
	cells.append_array(_mid(4, &"support", 2.0, 1.5))
	return cells


# --- CATEGORY 4: Elite Encounters ---

static func _t22_boss_center() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(1, &"elite", 3.0, 2.5))
	cells.append_array(_sym(2, 0, &"tank", 1.5, 1.0))
	cells.append_array(_sym(2, 3, &"tank", 1.5, 1.0))
	cells.append_array(_sym(1, 1, &"front"))
	cells.append_array(_sym(5, 4, &"front"))
	return cells


static func _t23_charge_lane() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(0, &"elite", 2.5, 2.0))
	cells.append_array(_sym(4, 1, &"tank", 1.0, 3.0))
	cells.append_array(_sym(1, 0, &"front", 1.5, 1.0))
	cells.append_array(_sym(1, 4, &"front", 1.5, 1.0))
	cells.append_array(_mid(5, &"front"))
	return cells


static func _t24_twin_bosses() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(2, 0, &"elite", 2.0, 2.0))
	cells.append_array(_mid(0, &"tank", 2.0, 1.5))
	cells.append_array(_sym(4, 3, &"support", 1.5, 1.0))
	cells.append_array(_mid(4, &"front", 2.0, 1.0))
	return cells


static func _t25_fortress() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(2, 0, &"tank", 2.0, 1.0))
	cells.append_array(_mid(0, &"tank", 2.0, 1.0))
	cells.append_array(_sym(1, 2, &"tank", 1.0, 2.0))
	cells.append_array(_mid(2, &"elite", 2.5, 2.0))
	cells.append_array(_sym(4, 4, &"support", 1.5, 1.0))
	cells.append_array(_mid(5, &"front", 2.0, 1.0))
	return cells


static func _t26_gauntlet() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"front", 1.5, 1.0))
	cells.append_array(_sym(5, 0, &"front"))
	cells.append_array(_sym(2, 1, &"tank", 2.0, 1.5))
	cells.append_array(_sym(4, 3, &"support", 1.5, 1.5))
	cells.append_array(_mid(5, &"elite", 3.0, 2.0))
	return cells


static func _t27_pincer() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(1, 0, &"elite", 2.0, 2.0))
	cells.append_array(_mid(0, &"tank", 2.5, 1.5))
	cells.append_array(_sym(4, 2, &"support"))
	cells.append_array(_sym(5, 3, &"front"))
	cells.append_array(_sym(6, 3, &"front"))
	cells.append_array(_mid(4, &"front", 1.5, 1.0))
	return cells


static func _t28_dragons_nest() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_mid(1, &"elite", 3.0, 2.5))
	cells.append_array(_sym(2, 0, &"support", 1.5, 1.5))
	cells.append_array(_sym(1, 3, &"support", 1.5, 1.0))
	cells.append_array(_sym(3, 5, &"tank", 2.0, 1.0))
	cells.append_array(_mid(5, &"tank", 2.0, 1.0))
	cells.append_array(_sym(5, 0, &"front"))
	return cells


# --- CATEGORY 5: Mixed Chaos ---

static func _t29_full_mix() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(4, 0, &"front", 1.5, 1.0))
	cells.append_array(_mid(0, &"front"))
	cells.append_array(_sym(2, 1, &"tank", 2.0, 1.5))
	cells.append_array(_sym(5, 2, &"support", 1.5, 1.5))
	cells.append_array(_mid(4, &"elite", 2.5, 2.0))
	cells.append_array(_sym(1, 5, &"front"))
	return cells


static func _t30_moving_maze() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(2, 0, &"tank", 2.0, 1.5))
	cells.append_array(_mid(0, &"tank", 2.0, 1.5))
	cells.append_array(_sym(1, 2, &"support", 1.5, 1.0))
	cells.append_array(_sym(4, 2, &"support", 1.5, 1.0))
	cells.append_array(_mid(2, &"support"))
	cells.append_array(_sym(3, 4, &"tank", 2.0, 1.0))
	cells.append_array(_mid(3, &"front", 1.5, 1.5))
	return cells


static func _t31_siege() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(1, 0, &"elite", 2.0, 1.5))
	cells.append_array(_sym(4, 1, &"tank", 1.5, 1.0))
	cells.append_array(_sym(4, 3, &"tank"))
	cells.append_array(_mid(4, &"tank", 2.0, 1.0))
	cells.append_array(_mid(2, &"front", 2.0, 1.5))
	cells.append_array(_sym(1, 5, &"support"))
	return cells


static func _t32_storm() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(2, 0, &"elite", 2.0, 2.0))
	cells.append_array(_mid(2, &"elite", 2.5, 2.0))
	cells.append_array(_sym(1, 3, &"support", 1.5, 1.0))
	cells.append_array(_sym(5, 3, &"support", 1.5, 1.0))
	cells.append_array(_sym(3, 5, &"front"))
	cells.append_array(_mid(5, &"front"))
	return cells


static func _t33_final_stand() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"tank", 2.0, 1.5))
	cells.append_array(_mid(0, &"tank", 2.0, 1.5))
	cells.append_array(_sym(1, 1, &"front", 1.5, 1.0))
	cells.append_array(_sym(4, 2, &"support", 2.0, 1.5))
	cells.append_array(_sym(1, 3, &"tank", 1.5, 1.5))
	cells.append_array(_mid(4, &"elite", 3.0, 2.5))
	cells.append_array(_sym(3, 6, &"front"))
	cells.append_array(_mid(6, &"support", 1.5, 1.0))
	return cells


static func _t34_dragon_lair() -> Array[FormationCell]:
	var cells: Array[FormationCell] = []
	cells.append_array(_sym(3, 0, &"tank", 2.5, 1.5))
	cells.append_array(_sym(1, 2, &"elite", 2.5, 2.0))
	cells.append_array(_mid(3, &"elite", 3.0, 2.5))
	cells.append_array(_sym(1, 5, &"support", 1.5, 1.0))
	cells.append_array(_sym(3, 6, &"tank", 2.0, 1.0))
	cells.append_array(_mid(6, &"tank", 2.0, 1.0))
	return cells
