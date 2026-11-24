extends SceneTree

func _initialize() -> void:
	var inventory := RPGInventory.new()
	var potion := RPGItemData.new()
	potion.item_id = &"potion"
	potion.display_name = "Potion"
	potion.max_stack = 3
	potion.hp_restore = 3

	assert(not inventory.register_item(null), "Null item definitions must be rejected")
	assert(inventory.register_item(potion), "Valid item definitions must be registered")
	assert(inventory.add_item(&"unknown") == 0, "Unknown items must not be added")
	assert(inventory.add_item(&"potion", 2) == 2, "Items must be added in stacks")
	assert(inventory.count(&"potion") == 2, "Inventory quantity must be tracked")
	assert(inventory.item_ids() == [&"potion"], "Item listing must include owned items only")
	assert(inventory.add_item(&"potion", 5) == 1, "Stacks must respect their configured limit")
	assert(inventory.count(&"potion") == 3, "Inventory must not exceed the stack limit")
	assert(inventory.add_item(&"potion", 0) == 0, "Zero additions must be rejected")
	assert(not inventory.remove_item(&"potion", 4), "Removing more than owned must fail")
	assert(not inventory.remove_item(&"potion", 0), "Zero removals must be rejected")
	assert(inventory.remove_item(&"potion", 2), "Owned items must be removable")
	assert(inventory.count(&"potion") == 1, "Removal must update the quantity")
	assert(inventory.remove_item(&"potion"), "The last item must be removable")
	assert(inventory.count(&"potion") == 0, "Empty stacks must be removed")
	assert(inventory.item_ids().is_empty(), "Empty inventory must return no item IDs")

	inventory.free()
	print("Inventory tests passed: registration, stacking, limits and removal.")
	quit()
