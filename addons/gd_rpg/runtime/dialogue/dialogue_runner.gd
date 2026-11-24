class_name RPGDialogueRunner
extends Node
## Plays dialogue lines and exposes signals for any UI to consume.

signal line_started(text: String, index: int)
signal dialogue_finished

var _lines: Array[String] = []
var _index: int = -1
var is_running: bool = false

func start(dialogue: RPGDialogue) -> void:
	if dialogue == null or not dialogue.is_valid():
		push_warning("Cannot start an empty or invalid dialogue.")
		return
	_lines = dialogue.lines
	_index = -1
	is_running = true
	advance()

func advance() -> void:
	if not is_running:
		return
	_index += 1
	if _index >= _lines.size():
		is_running = false
		dialogue_finished.emit()
		return
	line_started.emit(_lines[_index], _index)

func stop() -> void:
	is_running = false
	_lines.clear()
	_index = -1
