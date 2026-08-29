extends Node2D

@onready var bell_node: Node2D = $Bell
@onready var next_day_node: Node2D = $Next

# Reference the Document node script class
const DocumentScript = preload("res://Scripts/document.gd") # Replace path with your Document script path

var max_customers_today: int = 0

func _ready() -> void:
	max_customers_today = randi_range(10, 15)
	
	next_day_node.visible = false
	bell_node.visible = true

	Global.next_customer_requested.connect(_on_next_customer_requested)
	Global.next_day_requested.connect(_on_next_day_requested)
	Global.document_processed.connect(_on_document_processed)


func _on_next_customer_requested() -> void:
	# Spawn a customer only if under the daily limit
	if DocumentScript.daily_documents.size() < max_customers_today:
		call_next_customer()

func call_next_customer() -> void:
	# Your customer spawn logic here...
	Global.customer_arrived.emit()

func _on_document_processed() -> void:
	var total_processed := DocumentScript.daily_documents.size()
	print("[GAME] Customers served today: %d / %d" % [total_processed, max_customers_today])

	# End of day reached: Swap Bell with Next Day button
	if total_processed >= max_customers_today:
		bell_node.visible = false
		next_day_node.visible = true

func _on_next_day_requested() -> void:
	# Ensure the path matches your FileSystem exactly: res://Game/end_day.tscn
	var error_code := get_tree().change_scene_to_file("res://Game/EndDay.tscn")
	if error_code != OK:
		print("[ERROR] Failed to load end_day.tscn. Code: ", error_code)
