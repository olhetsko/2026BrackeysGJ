extends Node

signal customer_arrived
var document_decision: String = ""




signal document_processed
signal next_customer_requested
signal next_day_requested

var current_day: int = 1
var daily_results: Array[Dictionary] = []

func record_customer_decision(customer_data: Dictionary, action_taken: String) -> void:
	var has_error: bool = customer_data.get("has_error", false)
	var is_correct: bool = false
	
	if action_taken == "accepted":
		is_correct = not has_error
	elif action_taken == "declined":
		is_correct = has_error
		
	daily_results.append({
		"id": customer_data.get("id", "000"),
		"name": customer_data.get("name", "Unknown"),
		"action": action_taken,
		"is_correct": is_correct,
		"full_document": customer_data
	})

func advance_day() -> void:
	current_day += 1
	daily_results.clear()

# Master array to store all customer entry dictionaries for the day
var daily_documents: Array[Dictionary] = []


# Resets array manually if restarting the day
func start_new_day() -> void:
	daily_documents.clear()
	print("[GLOBAL] New day started. Document history cleared.")
