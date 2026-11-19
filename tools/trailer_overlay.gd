extends Control
var title=""
var subtitle=""
var black=0.0
var end_slate=false
var font: SystemFont
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font=SystemFont.new(); font.font_names=PackedStringArray(["Bahnschrift","Segoe UI"])
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,get_viewport_rect().size/Vector2(1600,900))
	if end_slate:
		draw_rect(Rect2(0,0,1600,900),Color("07131c"))
		draw_rect(Rect2(130,302,54,4),Color("76e9df"))
		draw_string(font,Vector2(126,420),"SUBTERRANEA",HORIZONTAL_ALIGNMENT_LEFT,-1,94,Color("e8edeb"))
		draw_string(font,Vector2(132,489),"THE NEREID CAMPAIGN",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("76e9df"))
		draw_string(font,Vector2(132,617),"THREE OPERATIONS. SIX DEGREES OF FREEDOM.",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("a2b6be"))
		draw_string(font,Vector2(132,667),"PLAY THE CAMPAIGN / WINDOWS PC",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("ffb76b"))
	else:
		draw_rect(Rect2(0,0,1600,40),Color(0.015,0.03,0.04,0.92))
		draw_rect(Rect2(0,730,1600,170),Color(0.015,0.03,0.04,0.95))
		draw_string(font,Vector2(70,793),title,HORIZONTAL_ALIGNMENT_LEFT,-1,39,Color("e8edeb"))
		draw_string(font,Vector2(73,844),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("76e9df"))
	if black>0: draw_rect(Rect2(0,0,1600,900),Color(0,0,0,black))
