extends TextureButton

enum State {
	OPEN,
	BUTTER,
	BATTERED,
	CLOSED,
	FLIPPED,
	COOKED,
	FINISHED
}

# lets me change image as per state
# you gotta drag images in here
@export var img_open: Texture2D
@export var img_butter: Texture2D
@export var img_batter: Texture2D
@export var img_closed: Texture2D
@export var img_flipped: Texture2D
@export var img_cooked: Texture2D
@export var img_finished: Texture2D

# buttons
@export var butter: Button
@export var batter: Button

#manages states. OPEN cause we start in that state
var state: State = State.OPEN

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_pressed)
	_apply_state()


# depending on signal go to a state
func _on_pressed() -> void:
	if state==State.OPEN and butter.button_pressed:
		print("OPEN to BUTTER")
		butter.button_pressed=false
		state=State.BUTTER
		_apply_state()
	
	if state==State.BUTTER and batter.button_pressed:
		print("BUTTER to BATTERED")
		batter.button_pressed=false
		state=State.BATTERED
		_apply_state()
	
	elif state!=State.OPEN and state!=State.BUTTER:
		state = (state + 1) % State.size()
		_apply_state()


func _apply_state() -> void:
	match state:
		State.OPEN:
			disabled = false
			texture_normal = img_open
			
		State.BUTTER:
			disabled = false
			texture_normal = img_butter
		
		State.BATTERED:
			disabled = false
			texture_normal = img_batter
			
		State.CLOSED:
			disabled = false
			texture_normal = img_closed

		State.FLIPPED:
			disabled = false
			texture_normal = img_flipped
		
		State.COOKED:
			disabled = false
			texture_normal = img_cooked
			
		State.FINISHED:
			disabled = false
			texture_normal = img_finished

#figure out how to go from FINISHED state back to OPEN state
