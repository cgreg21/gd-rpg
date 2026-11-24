class_name RPGATBBattle
extends Node
## Simple reusable Active Time Battle gauge manager.
## Participants may expose an "atb_speed" metadata value (default: 1.0).

signal gauge_changed(battler: Node, value: float, maximum: float)
signal gauge_ready(battler: Node)
signal battle_started
signal battle_ended

@export_range(0.1, 10.0, 0.1) var charge_rate: float = 1.0
@export_range(1.0, 100.0, 1.0) var gauge_max: float = 100.0

var battlers: Array[Node] = []
var _gauges: Dictionary = {}
var _ready_ids: Dictionary = {}
var running: bool = false


func start_battle(participants: Array[Node]) -> void:
	stop_battle()
	for battler in participants:
		if is_instance_valid(battler) and not battlers.has(battler):
			battlers.append(battler)
			_gauges[battler.get_instance_id()] = 0.0
	running = not battlers.is_empty()
	if running:
		battle_started.emit()


func _process(delta: float) -> void:
	if not running:
		return
	for battler in battlers:
		if not is_instance_valid(battler):
			continue
		var key := battler.get_instance_id()
		if _ready_ids.has(key):
			continue
		var speed := maxf(0.1, float(battler.get_meta("atb_speed", 1.0)))
		var value := minf(gauge_max, float(_gauges.get(key, 0.0)) + delta * charge_rate * speed)
		_gauges[key] = value
		gauge_changed.emit(battler, value, gauge_max)
		if value >= gauge_max:
			_ready_ids[key] = true
			gauge_ready.emit(battler)


## Resets a full gauge after the battler's command has been resolved.
func consume_turn(battler: Node) -> bool:
	if not is_instance_valid(battler):
		return false
	var key := battler.get_instance_id()
	if not _ready_ids.has(key):
		return false
	_ready_ids.erase(key)
	_gauges[key] = 0.0
	gauge_changed.emit(battler, 0.0, gauge_max)
	return true


func remove_battler(battler: Node) -> void:
	if not is_instance_valid(battler):
		return
	var key := battler.get_instance_id()
	battlers.erase(battler)
	_gauges.erase(key)
	_ready_ids.erase(key)
	if battlers.is_empty() and running:
		stop_battle()


func stop_battle() -> void:
	if not running and battlers.is_empty():
		return
	running = false
	battlers.clear()
	_gauges.clear()
	_ready_ids.clear()
	battle_ended.emit()


func get_gauge(battler: Node) -> float:
	if not is_instance_valid(battler):
		return 0.0
	return float(_gauges.get(battler.get_instance_id(), 0.0))


func get_gauge_ratio(battler: Node) -> float:
	if gauge_max <= 0.0:
		return 0.0
	return clampf(get_gauge(battler) / gauge_max, 0.0, 1.0)


func is_ready(battler: Node) -> bool:
	return is_instance_valid(battler) and _ready_ids.has(battler.get_instance_id())
