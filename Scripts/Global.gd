extends Node

# Rung by the bell, answered by People. A signal instead of a polled flag, so
# the request can't be missed, double-handled, or seen for more than one frame.
signal next_customer_requested

# Emitted the moment a customer finishes walking up to the counter. The
# document scene answers this by rolling a new person and sliding open, so the
# paper is driven by the arrival itself rather than by anyone poking a variable.
signal customer_arrived

var document_decision: String = ""
var current_day: int = 1
var daily_results: Array[Dictionary] = []

func advance_day() -> void:
	current_day += 1
	daily_results.clear()
