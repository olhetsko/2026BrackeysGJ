extends Node

## Emitted by a candle the moment it is put out. The dark veil listens for this.
signal Candle_extinguished

var Is_attacking = false
var Open_door = false
var Moving = true
var Level = 0
var Candle_lit = true
