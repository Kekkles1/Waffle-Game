extends Control

@onready var batter: Button = $Batter
@onready var butter: Button = $Butter
@onready var iron: Control = $Iron

func _ready() -> void:
	butter.pressed.connect(iron.butter_enable)
	#get listener here
