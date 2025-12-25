extends Control

signal piece_added(piece)
signal piece_removed(piece)
signal overfill_attempt(piece)

enum PlateType { QUARTER, HALF, FULL }

@export var plate_type: PlateType = PlateType.FULL

# Base plate textures (different sprite per plate size)
@export var tex_plate_quarter: Texture2D
@export var tex_plate_half: Texture2D
@export var tex_plate_full: Texture2D

# Ghost opacity + warning timing
@export var ghost_alpha: float = 0.55
@export var warning_flash_time: float = 0.18

@onready var base: TextureRect = $Base
@onready var ghost: TextureRect = $WaffleSlot/Ghost
@onready var content: Control = $WaffleSlot/Content
@onready var warning: ColorRect = $Warning

var capacity_quarters: int = 4
var used_quarters: int = 0
var pieces: Array = [] # Array of WafflePiece nodes (generic)

func _ready() -> void:
	# Capacity + base sprite
	match plate_type:
		PlateType.QUARTER:
			capacity_quarters = 1
			if tex_plate_quarter: base.texture = tex_plate_quarter
		PlateType.HALF:
			capacity_quarters = 2
			if tex_plate_half: base.texture = tex_plate_half
		PlateType.FULL:
			capacity_quarters = 4
			if tex_plate_full: base.texture = tex_plate_full

	# Default visuals
	ghost.visible = false
	ghost.modulate.a = ghost_alpha
	warning.visible = false

# ---------------------------
# Helpers
# ---------------------------

func _get_piece_quarters_count(piece) -> int:
	# Expects piece.quarters_count (int). Falls back to 1 if missing.
	if piece == null:
		return 0
	if "quarters_count" in piece:
		return int(piece.quarters_count)
	return 1

func _set_piece_plated_flags(piece, plated: bool) -> void:
	# Optional fields, won’t crash if missing.
	if piece == null:
		return
	if "is_plated" in piece:
		piece.is_plated = plated
	if "cut_locked" in piece:
		piece.cut_locked = plated
	if "current_plate" in piece:
		piece.current_plate = self if plated else null

func _get_piece_plate_sprite(piece) -> Texture2D:
	# Optional method:
	# - piece.get_plate_sprite()
	# Optional property fallback:
	# - piece.plate_sprite
	if piece == null:
		return null

	if piece.has_method("get_plate_sprite"):
		var t = piece.call("get_plate_sprite")
		if t is Texture2D:
			return t

	if "plate_sprite" in piece and piece.plate_sprite is Texture2D:
		return piece.plate_sprite

	# If the piece is a Control/Node2D with a child TextureRect/Sprite2D,
	# we intentionally do NOT guess here. Return null safely.
	return null

# ---------------------------
# Preview / Ghost
# ---------------------------

func can_accept(piece) -> bool:
	if piece == null:
		return false
	var q: int = _get_piece_quarters_count(piece)
	return used_quarters + q <= capacity_quarters

func show_preview(piece) -> void:
	# Call this on hover while dragging a piece over the plate.
	if piece == null:
		hide_preview()
		return

	if can_accept(piece):
		ghost.texture = _get_piece_plate_sprite(piece)
		ghost.visible = ghost.texture != null
		warning.visible = false
	else:
		ghost.visible = false
		warning.visible = true

func hide_preview() -> void:
	ghost.visible = false
	warning.visible = false

# ---------------------------
# Place / Remove
# ---------------------------

func accept(piece) -> bool:
	if piece == null:
		return false

	if not can_accept(piece):
		emit_signal("overfill_attempt", piece)
		flash_warning()
		hide_preview()
		return false

	# Update state
	var q: int = _get_piece_quarters_count(piece)
	pieces.append(piece)
	used_quarters += q

	_set_piece_plated_flags(piece, true)

	# Move node under plate content
	if piece.get_parent() != content:
		piece.reparent(content)

	emit_signal("piece_added", piece)
	hide_preview()
	return true

func remove(piece) -> void:
	if piece == null:
		return
	if piece not in pieces:
		return

	pieces.erase(piece)
	used_quarters -= _get_piece_quarters_count(piece)
	if used_quarters < 0:
		used_quarters = 0

	_set_piece_plated_flags(piece, false)

	emit_signal("piece_removed", piece)
	# NOTE: We do NOT reparent it back automatically because BuildScene/BuildManager
	# should decide where removed pieces go (cutting board, hand, etc.).

func remove_last() -> void:
	if pieces.size() == 0:
		return
	var piece = pieces[pieces.size() - 1]
	remove(piece)

func clear_plate(destroy_pieces: bool = false) -> void:
	# Used by trashcan: clear contents.
	# If destroy_pieces = true, the plate deletes the pieces.
	for p in pieces:
		_set_piece_plated_flags(p, false)
		if destroy_pieces and is_instance_valid(p):
			p.queue_free()
	pieces.clear()
	used_quarters = 0
	hide_preview()

# ---------------------------
# Warning
# ---------------------------

func flash_warning() -> void:
	warning.visible = true
	await get_tree().create_timer(warning_flash_time).timeout
	if is_instance_valid(warning):
		warning.visible = false
