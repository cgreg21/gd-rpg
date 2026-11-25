class_name RPGEventRunner
extends Node
## Executes a small sequence of RPG event commands.

signal message_requested(text: String)
signal switch_changed(name: StringName, value: bool)
signal completed
signal cancelled

var is_running := false
var _commands: Array[RPGEventCommand] = []
var _index := 0
var _switches: Dictionary = {}
var _character: Node2D
var _map_router: Node
var _waiting_for_message := false
var _wait_remaining := 0.0
var _moving_character: Node2D
var _move_start := Vector2.ZERO
var _move_target := Vector2.ZERO
var _move_duration := 0.0
var _move_elapsed := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if not is_running or _waiting_for_message:
		return
	if _wait_remaining > 0.0:
		_wait_remaining -= delta
		if _wait_remaining <= 0.0:
			_next_command()
		return
	if _moving_character == null:
		return
	if not is_instance_valid(_moving_character):
		_cancel()
		return
	_move_elapsed += delta
	var weight := minf(_move_elapsed / _move_duration, 1.0)
	_moving_character.global_position = _move_start.lerp(_move_target, weight)
	if weight >= 1.0:
		_moving_character.global_position = _move_target
		_moving_character = null
		_next_command()

func start(event: RPGEvent, character: Node2D = null, map_router: Node = null) -> bool:
	if is_running or event == null or not event.is_valid():
		return false
	_commands = event.commands
	_index = 0
	_character = character
	_map_router = map_router
	is_running = true
	call_deferred("_run_next_command")
	return true

func advance() -> void:
	if not is_running or not _waiting_for_message:
		return
	_waiting_for_message = false
	_next_command()

func stop() -> void:
	if is_running:
		_cancel()

func get_switch(name: StringName, default_value: bool = false) -> bool:
	return bool(_switches.get(name, default_value))

func set_switch(name: StringName, value: bool) -> void:
	if name.is_empty():
		return
	_switches[name] = value
	switch_changed.emit(name, value)

func _run_next_command() -> void:
	while is_running:
		if _index >= _commands.size():
			_finish()
			return
		var command := _commands[_index]
		match command.type:
			RPGEventCommand.Type.SHOW_MESSAGE:
				_waiting_for_message = true
				message_requested.emit(command.message)
				return
			RPGEventCommand.Type.WAIT:
				if command.duration <= 0.0:
					_index += 1
					continue
				_wait_remaining = command.duration
				return
			RPGEventCommand.Type.MOVE_CHARACTER:
				if _character == null or not is_instance_valid(_character):
					_cancel()
					return
				_moving_character = _character
				_move_start = _character.global_position
				_move_target = command.target_position
				_move_duration = command.duration
				_move_elapsed = 0.0
				return
			RPGEventCommand.Type.SET_SWITCH:
				set_switch(command.switch_name, command.switch_value)
				_index += 1
			RPGEventCommand.Type.TRANSFER_MAP:
				if _map_router == null or not is_instance_valid(_map_router):
					_cancel()
					return
				_map_router.call("transition_to", command.scene_path, command.spawn_id)
				_index += 1

func _next_command() -> void:
	_index += 1
	_run_next_command()

func _finish() -> void:
	is_running = false
	_reset_runtime()
	completed.emit()

func _cancel() -> void:
	is_running = false
	_reset_runtime()
	cancelled.emit()

func _reset_runtime() -> void:
	_commands.clear()
	_index = 0
	_character = null
	_map_router = null
	_waiting_for_message = false
	_wait_remaining = 0.0
	_moving_character = null
