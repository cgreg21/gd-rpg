@tool
extends EditorPlugin

const CHARACTER_SCRIPT := preload("res://addons/gd_rpg/runtime/character/rpg_character.gd")
const INTERACTABLE_SCRIPT := preload("res://addons/gd_rpg/runtime/interaction/rpg_interactable.gd")

func _enter_tree() -> void:
	add_custom_type("RPGCharacter", "CharacterBody2D", CHARACTER_SCRIPT, null)
	add_custom_type("RPGInteractable", "Area2D", INTERACTABLE_SCRIPT, null)

func _exit_tree() -> void:
	remove_custom_type("RPGInteractable")
	remove_custom_type("RPGCharacter")
