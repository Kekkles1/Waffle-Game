extends TextureButton

enum State {
	EMPTY,
	BUTTER,
	BATTERED
}

@onready var iron: Control = get_parent()
@onready var batter:= $CookScene/Control/Batter

# images here
@export var img_0_empty: Texture2D
@export var img_0_butter: Texture2D
@export var img_0_batter: Texture2D

var state:State = State.EMPTY

func _ready() -> void:
	self.pressed.connect(_on_pressed)
	#batter.pressed.connect(_on_pressed)
	

func _on_pressed() -> void:
	if iron.butter_enabled:
		print("BUTTER APPLIED")
		state = State.BUTTER
		iron.butter_enabled=false
		iron.batter_enabled=true
		_apply_state()
	
	elif iron.batter_enabled and batter.pressed:
		print("BATTER APPLIED")
		state = State.BATTERED
		_apply_state()
	
	_apply_state()
	
func _apply_state() -> void:
	match state:
		State.EMPTY:
			disabled = false
			texture_normal = img_0_empty
			
		State.BUTTER:
			disabled = false
			texture_normal = img_0_butter
			
		State.BATTERED:
			disabled = false
			texture_normal = img_0_batter
