extends CanvasLayer
class_name UpgradeSelection

signal all_picks_done

const UPGRADE_CARD_SCENE: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")
const UPGRADES_DIR: String = "res://data/upgrades/"
const PICKS_PER_LEVEL: int = 3
const CARDS_PER_PICK: int = 3

var _all_upgrades: Array[UpgradeData] = []
var _current_pick: int = 0

@onready var _overlay: ColorRect = $Overlay
@onready var _title_label: Label = $Overlay/VBox/TitleLabel
@onready var _card_container: HBoxContainer = $Overlay/VBox/CardContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_all_upgrades()
	visible = false


func _load_all_upgrades() -> void:
	_all_upgrades.clear()
	if not DirAccess.dir_exists_absolute(UPGRADES_DIR):
		return

	var dir: DirAccess = DirAccess.open(UPGRADES_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = ResourceLoader.load(UPGRADES_DIR + file_name)
			if res is UpgradeData:
				_all_upgrades.append(res as UpgradeData)
		file_name = dir.get_next()
	dir.list_dir_end()


func show_selection() -> void:
	_current_pick = 0
	visible = true
	_show_pick_round()


func _show_pick_round() -> void:
	_title_label.text = "Choose an Upgrade (" + str(_current_pick + 1) + "/" + str(PICKS_PER_LEVEL) + ")"

	# Clear old cards
	# Remove old cards immediately (not queue_free, which waits until end of frame)
	for child: Node in _card_container.get_children():
		_card_container.remove_child(child)
		child.queue_free()

	# Pick 3 random upgrades
	var shuffled: Array[UpgradeData] = _all_upgrades.duplicate()
	shuffled.shuffle()
	var count: int = mini(CARDS_PER_PICK, shuffled.size())

	for i: int in range(count):
		var card: UpgradeCard = UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
		card.setup(shuffled[i])
		card.selected.connect(_on_card_selected)
		_card_container.add_child(card)


func _on_card_selected(upgrade: UpgradeData) -> void:
	UpgradeManager.apply_upgrade(upgrade)
	_current_pick += 1

	if _current_pick >= PICKS_PER_LEVEL:
		visible = false
		all_picks_done.emit()
	else:
		_show_pick_round()
