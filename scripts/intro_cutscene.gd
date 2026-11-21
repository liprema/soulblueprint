extends CanvasLayer

signal cutscene_finished

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var god_dialog_box: PanelContainer = $GodDialogBox
@onready var speaker_name_label: Label = $GodDialogBox/MarginContainer/VBoxContainer/SpeakerName
@onready var dialogue_label: Label = $GodDialogBox/MarginContainer/VBoxContainer/DialogueText
@onready var quest_tracker: VBoxContainer = $QuestTracker
@onready var hud_controls: Control = $HUDControls

# Реплики Богов вступительного пролога
var prologue_script: Array = [
	{
		"speaker": "—",
		"title": "Хроники Акаши",
		"text": "В начале не было ни плоти, ни времени...\nЛишь Память о том, что еще не свершилось."
	},
	{
		"speaker": "КРОНОС",
		"title": "Магистр Порядка",
		"text": "Нити истончились, Алатея. Внизу, в мире смертных, сердца очерствели.\nИх кармические узлы завязались намертво."
	},
	{
		"speaker": "АЛАТЕЯ",
		"title": "Ткачиха Судеб",
		"text": "Мы не можем сойти со своих престолов, Брат.\nНаше величие сокрушит хрупкую ткань их реальности."
	},
	{
		"speaker": "МИРА",
		"title": "Матерь Утешения",
		"text": "Тогда пусть пойдет Та, кто еще не знала земной тяжести.\nЧистая Искра без имени и предвзятости."
	},
	{
		"speaker": "ОРИОН",
		"title": "Звездный Архивариус",
		"text": "Ступай, дитя. Распутай первую судьбу.\nИ пусть Хроники решат, кем ты станешь."
	}
]

var current_step: int = 0
var is_cutscene_active: bool = true

func _ready() -> void:
	quest_tracker.modulate.a = 0.0
	hud_controls.modulate.a = 0.0
	god_dialog_box.modulate.a = 0.0
	dark_overlay.modulate.a = 1.0
	start_prologue()

func start_prologue() -> void:
	is_cutscene_active = true
	_show_next_dialogue()

func _input(event: InputEvent) -> void:
	if not is_cutscene_active:
		return
	# Игнорируем простое движение мыши
	if event is InputEventMouseMotion:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("blink") or (event is InputEventMouseButton and event.pressed):
		_show_next_dialogue()

func _show_next_dialogue() -> void:
	if current_step < prologue_script.size():
		var line = prologue_script[current_step]
		speaker_name_label.text = line["speaker"] + " • " + line["title"]
		dialogue_label.text = line["text"]
		
		# Плавный показ диалогового окна
		var tween = create_tween()
		tween.tween_property(god_dialog_box, "modulate:a", 1.0, 0.4)
		
		# Плавное проявление мира после первой фразы
		if current_step == 1:
			var bg_tween = create_tween()
			bg_tween.tween_property(dark_overlay, "modulate:a", 0.0, 2.0)
			
		current_step += 1
	else:
		_finish_cutscene()

func _finish_cutscene() -> void:
	is_cutscene_active = false
	var tween = create_tween()
	# Прячем окно диалога
	tween.tween_property(god_dialog_box, "modulate:a", 0.0, 0.5)
	# Проявляем квест и кнопки способностей
	tween.parallel().tween_property(quest_tracker, "modulate:a", 1.0, 1.2)
	tween.parallel().tween_property(hud_controls, "modulate:a", 1.0, 1.2)
	
	cutscene_finished.emit()
