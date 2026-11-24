class_name RPGATBBattle
extends Node
## Lightweight ATB clock. Battlers can define an "atb_speed" metadata value.

signal gauge_ready(battler: Node)
signal battle_started
signal battle_ended

@export_range(0.1, 10.0, 0.1) var charge_rate: float = 1.0
@export_range(1.0, 100.0, 1.0) var gauge_max: float = 100.0

var battlers: Array[Node] = []
var _gauges: Dictionary = {}
var running: bool = false

func start_battle(participants: Array[Node]) -> void:
	battlers = participants.filter(func(item: Node) -> bool: return is_instance_valid(item))
	_gauges.clear()
	for battler in battlers:
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
		var speed := maxf(0.1, float(battler.get_meta("atb_speed", 1.0)))
		var value: float = _gauges.get(key, 0.0) + delta * charge_rate * speed
		if value >= gauge_max:
			value = 0.0
			gauge_ready.emit(battler)
		_gauges[key] = value

func stop_battle() -> void:
	if not running:
		return
	running = false
	battlers.clear()
	_gauges.clear()
	battle_ended.emit()

func get_gauge(battler: Node) -> float:
	if not is_instance_valid(battler):
		return 0.0
	return float(_gauges.get(battler.get_instance_id(), 0.0))
