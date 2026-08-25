extends Node

# Rung by the bell, answered by People. A signal instead of a polled flag, so
# the request can't be missed, double-handled, or seen for more than one frame.
signal next_customer_requested

# Emitted the moment a customer finishes walking up to the counter. The
# document scene answers this by rolling a new person and sliding open, so the
# paper is driven by the arrival itself rather than by anyone poking a variable.
signal customer_arrived

# Setting this fires pulldown_changed once, only on an actual change.
# Listeners react to the signal instead of polling in _process().
signal pulldown_changed(is_down: bool)

var Pulldown := false:
	set(value):
		if Pulldown == value:
			return
		Pulldown = value
		pulldown_changed.emit(value)
