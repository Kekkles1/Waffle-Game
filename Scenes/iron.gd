extends Control

@onready var iron0: TextureButton = $iron0

# boolean which locks the iron till u press butter
var butter_enabled = false
var batter_enabled = false

#modify so each quarter gets enabled?
func butter_enable() -> void:
	butter_enabled=true
	print("butter allowed")
