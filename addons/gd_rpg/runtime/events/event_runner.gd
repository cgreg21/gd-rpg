class_name RPGEventRunner
extends Node
## Executes a small sequence of RPG event commands.

signal message_requested(text: String)
signal switch_changed(name: StringName, value: bool)
signal completed
signal cancelled
signal step_released

var is_running := false
var _switches: Dictionary = {}
var _character: Node2D
var _map_router: Node

func start(event: RPGEvent, character: Node2D = null, map_router: Node = null) -> bool:
	if is_running or event == null or not event.is_valid():
		return false
	is_running = true
	_character = character
	_map_router = map_router
	_run_event.call_deferred(event)
	return true

func advance() -> void:
	if is_running:
		step_released.emit()

func stop() -> void:
	if not is_running:
		return
	is_running = false
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

func _run_event(event: RPGEvent) -> void:
	for command in event.commands:
		if not is_running:
			return
		var succeeded: bool = await _execute_command(command)
		if not succeeded:
			if is_running:
				is_running = false
				cancelled.emit()
			_character = null
			_map_router = null
			return
	is_running = false
	_character = null
	_map_router = null
	completed.emit()

func _execute_command(command: RPGEventCommand) -> bool:
	match command.type:
		RPGEventCommand.Type.SHOW_MESSAGE:
			message_requested.emit(command.message)
			await step_released
			return is_running
		RPGEventCommand.Type.WAIT:
			await get_tree().create_timer(command.duration).timeout
			return is_running
		RPGEventCommand.Type.MOVE_CHARACTER:
			return await _move_character(command)
		RPGEventCommand.Type.SET_SWITCH:
			set_switch(command.switch_name, command.switch_value)
			return is_running
		RPGEventCommand.Type.TRANSFER_MAP:
			if _map_router == null or not is_instance_valid(_map_router):
				return false
			_map_router.call("transition_to", command.scene_path, command.spawn_id)
			return is_running
	return false

func _move_character(command: RPGEventCommand) -> bool:
	if _character == null or not is_instance_valid(_character):
		return false
	var start_position := _character.global_position
	var elapsed := 0.0
	while elapsed < command.duration:
		await get_tree().process_frame
		if not is_running or not is_instance_valid(_character):
			return false
		elapsed += get_process_delta_time()
		var weight := minf(elapsed / command.duration, 1.0)
		_character.global_position = start_position.lerp(command.target_position, weight)
	return is_running
