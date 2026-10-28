class_name UiKit
extends RefCounted
## Small helpers that build Kenney-styled UI controls from code.

const FONT_PATH := "res://assets/ui/font/KenneyFuture.ttf"
const BUTTON_DIR := "res://assets/ui/buttons/"


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = load(FONT_PATH)
	theme.default_font_size = 26
	return theme


## A Kenney textured button. [param color] is blue, green, red, yellow or grey.
static func make_button(text: String, color := "blue", min_size := Vector2(340, 72)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	button.add_theme_constant_override("outline_size", 5)
	button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	var normal := _button_style(BUTTON_DIR + color + "_button00.png")
	var pressed := _button_style(BUTTON_DIR + color + "_button01.png")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func() -> void: AudioManager.play_sfx("ui_click", -6.0))
	return button


static func _button_style(path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	style.texture_margin_left = 10
	style.texture_margin_right = 10
	style.texture_margin_top = 10
	style.texture_margin_bottom = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style


static func make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.14, 0.92)
	style.border_color = Color(0.3, 0.8, 1.0, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(26)
	return style


static func make_label(text: String, size := 26, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	return label


static func make_bar(fill: Color, min_size := Vector2(300, 28)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = min_size
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.55)
	background.set_corner_radius_all(6)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill
	fill_style.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill_style)
	return bar
