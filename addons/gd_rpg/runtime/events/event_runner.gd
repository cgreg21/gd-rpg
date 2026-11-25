class_name RPGEventRunner
extends Node
## Executes a small sequence of RPG event commands.

signal message_requested(text: String)
signal switch_changed(name: StringName, value: bool)
signal completed
signal cancelled
signal step_released

var is_running := false
var _run_id := 0
var _switches: Dictionary = {}
var _character: Node2D
var _map_router: Node
var _moving_character: Node2D
var _move_start := Vector2.ZERO
var _move_target := Vector2.ZERO
var _move_duration := 0.0
var _move_elapsed := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if _moving_character == null:
		return
	if not is_instance_valid(_moving_character):
		_moving_character = null
		return
	_move_elapsed += delta
	var weight := minf(_move_elapsed / _move_duration, 1.0)
	_moving_character.global_position = _move_start.lerp(_move_target, weight)
	if weight >= 1.0:
		_moving_character = null

func start(event: RPGEvent, character: Node2D = null, map_router: Node = null) -> bool:
	if is_running or event == null or not event.is_valid():
		return false
	_run_id += 1
	is_running = true
	_character = character
	_map_router = map_router
	_run_event.call_deferred(event, _run_id)
	return true

func advance() -> void:
	if is_running:
		step_released.emit()

func stop() -> void:
	if not is_running:
		return
	_run_id += 1
	is_running = false
	_moving_character = null
	step_released.emit()
	cancelled.emit()
	_character = null
	_map_router = null

func get_switch(name: StringName, default_value: bool = false) -> bool:
	return bool(_switches.get(name, default_value))

func set_switch(name: StringName, value: bool) -> void:
	if name.is_empty():
		return
	_switches[name] = value
	switch_changed.emit(name, value)

func _run_event(event: RPGEvent, run_id: int) -> void:
	for command in event.commands:
		if not _is_current(run_id):
			return
		var succeeded: bool = await _execute_command(command, run_id)
		if not succeeded:
			if _is_current(run_id):
				is_running = false
				cancelled.emit()
				_character = null
				_map_router = null
			return
	if not _is_current(run_id):
		return
	is_running = false
	_character = null
	_map_router = null
	completed.emit()

func _execute_command(command: RPGEventCommand, run_id: int) -> bool:
	match command.type:
		RPGEventCommand.Type.SHOW_MESSAGE:
			message_requested.emit(command.message)
			await step_released
			return _is_current(run_id)
		RPGEventCommand.Type.WAIT:
			await get_tree().create_timer(command.duration).timeout
			return _is_current(run_id)
		RPGEventCommand.Type.MOVE_CHARACTER:
			return await _move_character(command, run_id)
		RPGEventCommand.Type.SET_SWITCH:
			set_switch(command.switch_name, command.switch_value)
			return _is_current(run_id)
		RPGEventCommand.Type.TRANSFER_MAP:
			if not _is_current(run_id) or _map_router == null or not is_instance_valid(_map_router):
				return false
			_map_router.call("transition_to", command.scene_path, command.spawn_id)
			return _is_current(run_id)
	return false

func _move_character(command: RPGEventCommand, run_id: int) -> bool:
	if not _is_current(run_id) or _character == null or not is_instance_valid(_character):
		return false
	_moving_character = _character
	_move_start = _character.global_position
	_move_target = command.target_position
	_move_duration = command.duration
	_move_elapsed = 0.0
	await get_tree().create_timer(command.duration).timeout
	if not _is_current(run_id) or not is_instance_valid(_character):
		return false
	_character.global_position = command.target_position
	_moving_character = null
	return true

func _is_current(run_id: int) -> bool:
	return is_running and run_id == _run_id
