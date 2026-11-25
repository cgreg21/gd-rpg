extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _make_command(type: RPGEventCommand.Type) -> RPGEventCommand:
	var command := RPGEventCommand.new()
	command.type = type
	return command

func _run() -> void:
	var runner := RPGEventRunner.new()
	root.add_child(runner)

	var event := RPGEvent.new()
	event.event_id = &"test_sequence"
	var message := _make_command(RPGEventCommand.Type.SHOW_MESSAGE)
	message.message = "The gate is open."
	var switch := _make_command(RPGEventCommand.Type.SET_SWITCH)
	switch.switch_name = &"gate_open"
	switch.switch_value = true
	event.commands = [message, switch]
	var messages: Array[String] = []
	var finished := false
	runner.message_requested.connect(func(value: String) -> void: messages.append(value))
	runner.completed.connect(func() -> void: finished = true)

	assert(runner.start(event), "A valid event must start")
	assert(not runner.start(event), "A running event must not start twice")
	await process_frame
	assert(messages == ["The gate is open."], "Message command must be emitted first")
	assert(not runner.get_switch(&"gate_open"), "Later commands must wait for message advance")
	runner.advance()
	await process_frame
	await process_frame
	assert(runner.get_switch(&"gate_open"), "Switch command must run after message advance")
	assert(finished and not runner.is_running, "Event must emit completed at the end")

	var character := Node2D.new()
	root.add_child(character)
	var move_event := RPGEvent.new()
	move_event.event_id = &"move"
	var move := _make_command(RPGEventCommand.Type.MOVE_CHARACTER)
	move.target_position = Vector2(20, 10)
	move.duration = 0.05
	move_event.commands = [move]
	finished = false
	assert(runner.start(move_event, character), "Move event must start with a character")
	await create_timer(0.1).timeout
	assert(character.global_position.is_equal_approx(Vector2(20, 10)), "Move command must reach its target")
	assert(finished, "Move event must complete")

	var wait_event := RPGEvent.new()
	wait_event.event_id = &"cancel_wait"
	var wait := _make_command(RPGEventCommand.Type.WAIT)
	wait.duration = 1.0
	wait_event.commands = [wait]
	var was_cancelled := false
	runner.cancelled.connect(func() -> void: was_cancelled = true)
	assert(runner.start(wait_event), "Wait event must start")
	runner.stop()
	await process_frame
	assert(was_cancelled and not runner.is_running, "Stopping an event must cancel it")

	var invalid_event := RPGEvent.new()
	invalid_event.event_id = &"invalid"
	var invalid_message := _make_command(RPGEventCommand.Type.SHOW_MESSAGE)
	invalid_event.commands = [invalid_message]
	assert(not invalid_event.is_valid(), "Empty messages must make an event invalid")
	assert(not runner.start(invalid_event), "Invalid events must not start")
	assert(not runner.start(null), "Null events must not start")

	var missing_character_event := RPGEvent.new()
	missing_character_event.event_id = &"missing_character"
	missing_character_event.commands = [move]
	assert(runner.start(missing_character_event), "Event runner accepts valid command data")
	await process_frame
	assert(not runner.is_running, "Move command without a character must stop the sequence")

	print("Event command tests passed.")
	quit()
