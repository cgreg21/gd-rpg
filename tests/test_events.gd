extends SceneTree

func _initialize() -> void:
	create_timer(15.0).timeout.connect(_on_timeout)
	call_deferred("_run")

func _on_timeout() -> void:
	push_error("Event tests timed out.")
	quit(1)

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
	var completed_count := 0
	runner.message_requested.connect(func(value: String) -> void: messages.append(value))
	runner.completed.connect(func() -> void:
		finished = true
		completed_count += 1
	)

	print("Event test: message sequence")
	assert(runner.start(event), "A valid event must start")
	assert(not runner.start(event), "A running event must not start twice")
	await process_frame
	assert(messages == ["The gate is open."], "Message command must be emitted first")
	assert(not runner.get_switch(&"gate_open"), "Later commands must wait for message advance")
	runner.advance()
	await runner.completed
	assert(runner.get_switch(&"gate_open"), "Switch command must run after message advance")
	assert(finished and not runner.is_running, "Event must emit completed at the end")

	print("Event test: movement")
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
	await runner.completed
	assert(character.global_position.is_equal_approx(Vector2(20, 10)), "Move command must reach its target")
	assert(finished, "Move event must complete")

	print("Event test: cancellation")
	var wait_event := RPGEvent.new()
	wait_event.event_id = &"cancel_wait"
	var wait := _make_command(RPGEventCommand.Type.WAIT)
	wait.duration = 1.0
	wait_event.commands = [wait]
	var was_cancelled := false
	runner.cancelled.connect(func() -> void: was_cancelled = true)
	assert(runner.start(wait_event), "Wait event must start")
	await process_frame
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

	print("Event test: restart after cancellation")
	var later_event := RPGEvent.new()
	later_event.event_id = &"later_wait"
	var later_wait := _make_command(RPGEventCommand.Type.WAIT)
	later_wait.duration = 2.0
	later_event.commands = [later_wait]
	assert(runner.start(later_event), "A new event must start after cancellation")
	await create_timer(1.1).timeout
	assert(runner.is_running, "The cancelled wait must not finish a later event")
	assert(completed_count == 2, "A cancelled event must not emit completed after a later event starts")
	runner.stop()
	assert(not runner.is_running, "The later event must stop cleanly")

	print("Event command tests passed.")
	quit()
