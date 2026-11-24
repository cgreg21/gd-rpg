class_name RPGInventory
extends Node
## Small stack-based inventory keyed by item ID.

var _definitions: Dictionary[StringName, RPGItemData] = {}
var _quantities: Dictionary[StringName, int] = {}

func register_item(item: RPGItemData) -> bool:
	if item == null or not item.is_valid():
		return false
	_definitions[item.item_id] = item
	return true

func get_item(item_id: StringName) -> RPGItemData:
	return _definitions.get(item_id)

func count(item_id: StringName) -> int:
	return _quantities.get(item_id, 0)

func item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for item_id in _quantities:
		ids.append(item_id)
	ids.sort()
	return ids

func add_item(item_id: StringName, amount: int = 1) -> int:
	if amount <= 0 or not _definitions.has(item_id):
		return 0
	var current := count(item_id)
	var capacity: int = _definitions[item_id].max_stack - current
	var added := mini(amount, maxi(0, capacity))
	if added > 0:
		_quantities[item_id] = current + added
	return added

func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or count(item_id) < amount:
		return false
	var remaining := count(item_id) - amount
	if remaining == 0:
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = remaining
	return true
