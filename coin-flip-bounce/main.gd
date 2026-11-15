extends Node2D

@onready var coin: RigidBody2D = $Coin
@onready var heads_button: Button = $CanvasLayer/HeadsButton
@onready var tails_button: Button = $CanvasLayer/TailsButton
@onready var cash_out_button: Button = $CanvasLayer/CashOutButton
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel

var player_guess: String = ""
var streak: int = 0
var run_points: int = 0
var banked_score: int = 0
var high_score: int = 0
var is_flipping: bool = false

func _ready() -> void:
	heads_button.pressed.connect(_on_guess_made.bind("Heads"))
	tails_button.pressed.connect(_on_guess_made.bind("Tails"))
	cash_out_button.pressed.connect(_on_cash_out)
	coin.coin_settled.connect(_on_coin_settled)
	
	_update_ui(true, "Pick Heads or Tails!")

func _on_guess_made(choice: String) -> void:
	if is_flipping:
		return
	
	is_flipping = true
	player_guess = choice
	
	_update_ui(false, "You picked " + choice + "...")
	coin.flip_coin()

func _on_coin_settled(result: String) -> void:
	is_flipping = false
	
	if player_guess == result:
		streak += 1
		# First win = 10 pts, then doubles every flip (10, 20, 40, 80...)
		run_points = 10 if streak == 1 else run_points * 2
		_update_ui(true, "Correct! Risk %d pts or Cash Out?" % run_points)
	else:
		streak = 0
		run_points = 0
		_update_ui(true, "Busted! Landed on " + result + ".")

func _on_cash_out() -> void:
	if is_flipping or run_points == 0:
		return
	
	banked_score += run_points
	if banked_score > high_score:
		high_score = banked_score
		# --> Send `high_score` to your leaderboard here! <--
		
	var saved = run_points
	streak = 0
	run_points = 0
	_update_ui(true, "Banked %d pts! Start a new streak." % saved)

func _update_ui(can_pick: bool, message: String) -> void:
	heads_button.disabled = not can_pick
	tails_button.disabled = not can_pick
	cash_out_button.disabled = not can_pick or run_points == 0
	
	status_label.text = message
	score_label.text = "Banked: %d | At Risk: %d (x%d)" % [banked_score, run_points, streak]
