extends Control
const C = Color("76e9df")
const A = Color("ffb970")
const WHITE = Color("e8edeb")
const MUTED = Color("8ba2ad")
var game: Node3D
var ui: Control
var settings_open = false
var front_view="title"
var journal_mission=0
var journal_radio=false
var save_message=""
var confirm_slot=-1
var confirm_load=-1
var profile_rows: Array=[]
const FLEET=[
	{"id":"kestrel","name":"KESTREL / INTERCEPTOR","info":"Your six-axis strike craft. Twin vector engines, split armor shoulders and a recessed armored canopy.","color":Color("76e9df")},
	{"id":"scout","name":"SCOUT / PURSUIT DRONE","info":"A narrow sensor head and swept outriggers identify this fast flanking machine. Watch for its red optic.","color":Color("ff7758")},
	{"id":"striker","name":"STRIKER / GUNSHIP","info":"Twin engine booms and long underslung cannons. Violet emitter strips mark the predictive-fire attacker.","color":Color("cba4ff")},
	{"id":"bulwark","name":"BULWARK / ARMORED DRONE","info":"Overlapping pale armor protects its front. Amber optics, recessed engines and a broad armored silhouette.","color":Color("ffbf70")},
	{"id":"warden","name":"WARDEN / VAULT GUARDIAN","info":"A split crown and raised shoulder reactors distinguish the reserve-vault guardian. Violet cores signal its overdrive.","color":Color("d4a6ff")},
	{"id":"overseer","name":"OVERSEER / COMMAND MACHINE","info":"A segmented armored wing, four forward cannons and a recessed command eye. The heart of the Helios fortress.","color":Color("ffae70")},
	{"id":"courier","name":"COURIER / CREW RESCUE","info":"A protected crew capsule, rescue markings and twin ducted vector jets. Follow its cyan signal to extraction.","color":Color("76e9df")}]
var fleet_index=0
var preview_drag=false
var preview_spin=true
var preview_camera: Camera3D
var livery_model: Node3D
var settings_tab="flight"
var listening_action=""
var binding_device="keyboard"
var font: SystemFont
var mono: SystemFont
var display: SystemFont

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift","Segoe UI"])
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas"])
	display = SystemFont.new()
	display.font_names = PackedStringArray(["Bahnschrift SemiBold","Bahnschrift","Segoe UI"])
	front_view=str(get_tree().root.get_meta("front_view","title"))
	rebuild_menu()

func _process(_delta: float) -> void:
	if is_instance_valid(livery_model) and livery_model.is_inside_tree() and preview_spin: livery_model.rotate_y(_delta*0.25)
	if is_instance_valid(ui): ui.scale = get_viewport_rect().size/Vector2(1600,900)
	queue_redraw()

func text_at(pos: Vector2,content: String,size_px: int = 18,color: Color = WHITE,technical: bool = false) -> void:
	draw_string(mono if technical else font,pos,content,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func line(a: Vector2,b: Vector2,color: Color = Color(0.46,0.72,0.75,0.3),width: float = 1) -> void:
	draw_line(a,b,color,width,true)

func panel(rect: Rect2,alpha: float = 0.7) -> void:
	draw_rect(rect,Color(0.025,0.055,0.075,alpha))
	draw_rect(rect,Color(0.4,0.7,0.74,0.18),false,1)

func button(label: String,pos: Vector2,dimensions: Vector2,action: Callable,primary: bool = false) -> Button:
	var b = Button.new()
	b.text = label
	b.position = pos
	b.size = dimensions
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font",font)
	b.add_theme_font_size_override("font_size",19)
	for mode in ["normal","hover","pressed","focus","disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = (C if primary else Color("152b38")) if mode=="normal" else (Color("a0fff0") if primary else Color("294b59"))
		style.border_color = C if primary else Color("3b606c")
		style.set_border_width_all(1)
		style.content_margin_left = 22
		style.content_margin_right = 22
		if mode=="disabled": style.bg_color=Color("11222c"); style.border_color=Color("263d47")
		b.add_theme_stylebox_override(mode,style)
	b.add_theme_color_override("font_color",Color("102a32") if primary else WHITE)
	b.add_theme_color_override("font_hover_color",Color("102a32") if primary else C)
	b.add_theme_color_override("font_focus_color",Color("102a32") if primary else WHITE)
	b.add_theme_color_override("font_pressed_color",Color("102a32") if primary else C)
	b.add_theme_color_override("font_disabled_color",Color("637b87"))
	b.pressed.connect(func(): game.sound.play_tone("ui",0.4); action.call())
	ui.add_child(b)
	return b

func rebuild_menu() -> void:
	if is_instance_valid(ui):
		remove_child(ui)
		ui.queue_free()
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	ui.scale = get_viewport_rect().size/Vector2(1600,900)
	if game.state == "playing":
		settings_open = false
		return
	if settings_open: build_settings()
	elif front_view=="profiles":
		profile_rows=game.profile_store.summaries()
		for row in profile_rows:
			var b=button("ACTIVE PROFILE" if row.active else ("USE PROFILE" if row.exists else "START NEW PROFILE"),Vector2(110+row.index*490,540),Vector2(380,50),func(): game.switch_profile(row.index),row.active)
			b.disabled=row.active or game.state=="paused"
		button("BACK TO SAVES",Vector2(80,755),Vector2(600,50),func(): front_view="saves"; rebuild_menu())
	elif front_view=="saves":
		button("CAMPAIGN PROFILES",Vector2(1040,160),Vector2(480,44),func(): front_view="profiles"; save_message=""; confirm_slot=-1; confirm_load=-1; rebuild_menu()).disabled=game.state=="paused"
		button("CONTINUE AUTOSAVE",Vector2(80,205),Vector2(600,50),game.continue_saved,true).disabled=game.campaign.data.checkpoint.is_empty()
		for i in range(3):
			var y=310+i*135
			var entry=game.campaign.data.manual_slots[i]
			var save=button("CONFIRM OVERWRITE" if confirm_slot==i else "SAVE CURRENT RUN",Vector2(1030,y+34),Vector2(230,44),func(): request_slot_save(i))
			save.disabled=game.state!="paused" or game.training_mode
			var load_button=button("CONFIRM LOAD" if confirm_load==i else "LOAD SLOT",Vector2(1280,y+34),Vector2(230,44),func(): request_slot_load(i))
			load_button.disabled=entry.is_empty()
		button("BACK TO PAUSE" if game.state=="paused" else "BACK TO FLIGHT DECK",Vector2(80,780),Vector2(600,48),func(): front_view="title"; confirm_slot=-1; confirm_load=-1; rebuild_menu())
	elif front_view=="journal":
		for index in range(3): button(["NEREID","BOREAS","HELIOS"][index],Vector2(80+index*310,175),Vector2(290,42),func(): journal_mission=index; rebuild_menu(),index==journal_mission)
		button("RADIO TRANSCRIPTS" if not journal_radio else "DATA RECORDERS",Vector2(1040,175),Vector2(480,42),func(): journal_radio=not journal_radio; rebuild_menu())
		button("BACK TO PAUSE MENU" if game.state=="paused" else "BACK TO FLIGHT DECK",Vector2(80,765),Vector2(600,50),func(): front_view="title"; rebuild_menu())
	elif front_view=="fleet" and game.state in ["menu","won","lost"]:
		build_livery_stage()
		for index in range(FLEET.size()):
			button(FLEET[index].name,Vector2(110,244+index*61),Vector2(560,48),func(): fleet_index=index; rebuild_menu(),index==fleet_index)
		button("BACK TO FLIGHT DECK",Vector2(110,755),Vector2(560,50),func(): front_view="title"; rebuild_menu())
	elif front_view=="livery" and game.state in ["menu","won","lost"]:
		build_livery_stage()
		for index in range(4):
			var entry=game.exploration.Lore.PAINTS[index]
			var unlocked=entry.id in game.campaign.data.paints
			var b=button(entry.title+(" / EQUIPPED" if entry.id==game.campaign.data.paint else (" / EQUIP" if unlocked else " / LOCKED")),Vector2(110,260+index*100),Vector2(560,44),func(): game.exploration.select_paint(entry.id); rebuild_menu(),entry.id==game.campaign.data.paint)
			b.disabled=not unlocked
		button("BACK TO FLIGHT DECK",Vector2(110,760),Vector2(560,50),func(): front_view="title"; rebuild_menu())
	elif front_view=="briefing" and game.state in ["menu","won","lost"]:
		button("LAUNCH OPERATION / ENTER",Vector2(100,735),Vector2(580,62),game.launch,true)
		button("BACK TO OPERATIONS",Vector2(710,735),Vector2(580,62),func(): front_view="campaign"; rebuild_menu())
	elif front_view=="credits" and game.state in ["menu","won","lost"]:
		button("RETURN TO FLIGHT DECK",Vector2(500,755),Vector2(600,54),func(): front_view="title"; rebuild_menu())
	elif game.training_mode and game.state in ["won","lost"]:
		button("CAMPAIGN OPERATIONS",Vector2(555,553),Vector2(490,56),game.return_to_hangar,true)
		button("REPEAT TRAINING",Vector2(555,625),Vector2(490,46),game.restart)
		button("QUIT TO DESKTOP",Vector2(555,687),Vector2(490,44),game.quit_game)
	elif front_view=="workshop" and game.state in ["menu","won","lost"]:
		for i in range(4):
			var part=["shields","engines","cannons","missiles"][i]
			var origin=Vector2(100+(i%2)*715,190+(i/2)*270)
			var level=game.campaign.level(part)
			var cost=game.campaign.cost(part)
			var label="FULLY UPGRADED" if level>=3 else "INSTALL / %d SALVAGE" % cost
			var buy=button(label,origin+Vector2(30,175),Vector2(590,46),func(): game.buy_upgrade(part),true)
			buy.disabled=level>=3 or game.campaign.data.salvage<cost
		button("BACK TO FLIGHT DECK",Vector2(100,760),Vector2(410,52),func(): front_view="title"; rebuild_menu())
		button("CAMPAIGN OPERATIONS",Vector2(530,760),Vector2(410,52),func(): front_view="campaign"; rebuild_menu())
		if game.state=="won": button("CONTINUE CAMPAIGN",Vector2(960,760),Vector2(505,52),func(): game.choose_mission(mini(2,game.mission_index+1)),true)
	elif game.state=="menu" or (front_view=="campaign" and game.state in ["won","lost"]):
		if front_view=="campaign":
			for i in range(3):
				var select=button("SELECT OPERATION" if i<=game.campaign.data.unlocked else "COMPLETE PREVIOUS OPERATION",Vector2(110+i*490,500),Vector2(380,52),func(): game.choose_mission(i),i==game.mission_index)
				select.disabled=i>game.campaign.data.unlocked
			button("DEPLOY SELECTED OPERATION / ENTER",Vector2(80,730),Vector2(430,58),show_briefing,true)
			button("UPGRADE BAY",Vector2(530,730),Vector2(300,58),func(): front_view="workshop"; rebuild_menu())
			button("BACK",Vector2(850,730),Vector2(190,58),func(): front_view="title"; rebuild_menu())
			if not game.campaign.data.checkpoint.is_empty(): button("CONTINUE CHECKPOINT",Vector2(1060,730),Vector2(440,58),game.continue_saved)
		else:
			var continuing=not game.campaign.data.checkpoint.is_empty()
			button("CONTINUE CHECKPOINT / ENTER" if continuing else "DEPLOY SHIP / ENTER",Vector2(86,510),Vector2(454,58),game.continue_saved if continuing else show_briefing,true)
			button("CAMPAIGN",Vector2(86,584),Vector2(220,46),func(): front_view="campaign"; rebuild_menu())
			button("UPGRADE BAY",Vector2(320,584),Vector2(220,46),func(): front_view="workshop"; rebuild_menu())
			button("FLIGHT SETTINGS",Vector2(86,646),Vector2(220,40),func(): settings_open=true; rebuild_menu())
			button("QUIT",Vector2(320,646),Vector2(220,40),game.quit_game)
			button("TRAINING HANGAR"+(" / CERTIFIED" if game.campaign.data.training_complete else " / START HERE"),Vector2(86,700),Vector2(454,42),game.start_training)
			button("MISSION JOURNAL",Vector2(1125,183),Vector2(390,40),show_journal)
			button("SHIP LIVERY",Vector2(1125,239),Vector2(390,40),func(): front_view="livery"; rebuild_menu())
			button("PROFILES & SAVES",Vector2(1125,295),Vector2(390,40),show_saves)
			button("FLEET HANGAR",Vector2(1125,351),Vector2(390,40),func(): front_view="fleet"; rebuild_menu())
			button("CREDITS",Vector2(1125,127),Vector2(390,40),func(): front_view="credits"; rebuild_menu())
	elif game.state == "paused":
		button("RESUME FLIGHT",Vector2(555,350),Vector2(490,48),game.resume,true)
		button("MISSION JOURNAL",Vector2(555,410),Vector2(490,40),show_journal)
		button("MANUAL SAVES",Vector2(555,458),Vector2(490,40),show_saves)
		button("FLIGHT SETTINGS",Vector2(555,506),Vector2(490,40),func(): settings_open=true; rebuild_menu())
		button("RESTART MISSION",Vector2(555,554),Vector2(490,40),game.restart)
		button("SAVE & RETURN TO FLIGHT DECK",Vector2(555,602),Vector2(490,40),game.return_to_hangar)
		button("SAVE & QUIT",Vector2(555,650),Vector2(490,40),game.quit_game)
	else:
		button("NEXT OPERATION" if game.mission_index<2 and game.state=="won" else "CAMPAIGN FLIGHT DECK",Vector2(555,553),Vector2(490,56),func(): game.choose_mission(mini(2,game.mission_index+1)) if game.state=="won" else game.return_to_hangar(),true)
		button("UPGRADE BAY",Vector2(555,625),Vector2(236,46),func(): front_view="workshop"; rebuild_menu())
		button("REPLAY MISSION",Vector2(809,625),Vector2(236,46),game.restart)
		button("QUIT TO DESKTOP",Vector2(555,687),Vector2(490,44),game.quit_game)

	call_deferred("focus_first")

func make_slider(pos: Vector2,low: float,high: float,value: float,changed: Callable) -> void:
	var slider = HSlider.new()
	slider.position = pos
	slider.size = Vector2(600,28)
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.01
	slider.value = value
	slider.value_changed.connect(func(value): changed.call(value); game.save_settings())
	ui.add_child(slider)

func _draw() -> void:
	if not is_instance_valid(game.player): return
	var base=get_viewport_rect().size/Vector2(1600,900)
	draw_set_transform(Vector2.ZERO,0,base)
	if game.state=="menu":
		if front_view not in ["livery","fleet"]: draw_title()
	else:
		var factor=1.0 if game.map_open else game.hud_scale
		draw_set_transform(Vector2(800,450)*(1-factor)*base,0,base*factor)
		draw_cockpit()
		draw_set_transform(Vector2.ZERO,0,base)
	if game.state in ["paused","won","lost"]: draw_overlay()
	if game.state in ["menu","won","lost"] and not settings_open:
		match front_view:
			"campaign": draw_campaign()
			"workshop": draw_workshop()
			"briefing": draw_briefing()
			"credits": draw_credits()
	if not settings_open and front_view=="profiles" and game.state!="playing": draw_profiles()
	if not settings_open and front_view=="saves" and game.state!="playing": draw_saves()
	if not settings_open and front_view=="journal" and game.state!="playing": draw_journal()
	if not settings_open and front_view=="livery" and game.state in ["menu","won","lost"]: draw_livery()
	if not settings_open and front_view=="fleet" and game.state in ["menu","won","lost"]: draw_fleet()
	if settings_open: draw_settings()

func brand(pos: Vector2,compact: bool = false) -> void:
	var s = 0.7 if compact else 1.0
	var a = pos+Vector2(0,-17*s)
	for i in range(3):
		var y = i*7*s
		line(a+Vector2(0,y),a+Vector2(13*s,8*s+y),C,2)
		line(a+Vector2(13*s,8*s+y),a+Vector2(26*s,y),C,2)
	text_at(pos+Vector2(40*s,0),"SUBTERRANEA",20 if compact else 25,WHITE,true)

func draw_title() -> void:
	# Layered translucent scrim retains the live hangar behind the flight deck.
	draw_rect(Rect2(0,0,710,900),Color(0.018,0.04,0.055,0.94))
	for i in range(30):
		draw_rect(Rect2(710+i*9,0,9,900),Color(0.018,0.04,0.055,0.72*(1-float(i)/30)))
	line(Vector2(86,135),Vector2(540,135))
	brand(Vector2(86,88))
	text_at(Vector2(86,182),"S I X - A X I S   C O M B A T   F L I G H T",14,C,true)
	text_at(Vector2(82,280),"BELOW THE",73,WHITE)
	text_at(Vector2(82,359),"SURFACE.",86,WHITE)
	draw_rect(Rect2(86,392,35,3),C)
	text_at(Vector2(86,435),game.mission_info().location,21,WHITE)
	text_at(Vector2(86,470),"Three operations. One way out.",22,MUTED)
	text_at(Vector2(86,764),"DEFAULT FLIGHT CONTROLS",13,C,true)
	text_at(Vector2(86,792),"WASD  Thrust / strafe   MOUSE / PAD  Steer",14,MUTED,true)
	text_at(Vector2(86,818),"SPACE / CTRL  Lift   Q / E  Roll   SHIFT  Boost",14,MUTED,true)
	text_at(Vector2(86,844),"1 / 2 / 3  Weapons   V / D-PAD RIGHT  Cycle primary",13,MUTED,true)

	text_at(Vector2(86,871),"3 OPERATIONS / SAVED CAMPAIGN / ORIGINAL ASSETS",11,Color("587883"),true)
	panel(Rect2(1125,55,390,57),0.5)
	draw_circle(Vector2(1149,83),3,C)
	text_at(Vector2(1164,89),"CAMPAIGN / AUTOSAVE READY",13,C,true)
	panel(Rect2(1110,609,405,225),0.74)
	text_at(Vector2(1136,644),"O P E R A T I O N   0 %d" % (game.mission_index+1),13,C,true)
	text_at(Vector2(1136,686),game.mission_info().title,22,WHITE)
	line(Vector2(1136,706),Vector2(1488,706))
	var steps=[["Disable three power relays","Destroy the reactor core","Return before containment fails"],["Recover three archives","Upload at the orbital uplink","Evade the interception fleet"],["Destroy three shield nodes","Defeat the Overseer","Escape the collapsing fortress"]][game.mission_index]
	for i in range(3): text_at(Vector2(1136,738+i*33),"0%d   %s" % [i+1,steps[i]],16,A if i==2 else MUTED)
	text_at(Vector2(1230,872),"SALVAGE / %05d" % game.campaign.data.salvage,12,MUTED,true)

func draw_cockpit() -> void:
	var p = game.player
	# Lightweight canopy geometry frames the world without obscuring targets.
	var faint = Color(0.4,0.8,0.8,0.2)
	line(Vector2(0,700),Vector2(190,760),faint,2)
	line(Vector2(190,760),Vector2(460,760),faint)
	line(Vector2(1600,700),Vector2(1410,760),faint,2)
	line(Vector2(1410,760),Vector2(1140,760),faint)
	brand(Vector2(42,49),true)
	text_at(Vector2(42,80),game.sector_name(),13,C,true)
	text_at(Vector2(42,105),"%s / DEPTH %s M" % [game.mission_info().location.get_slice(" / ",0),str(game.depth-int(p.position.y))],11,MUTED,true)
	if not game.training_mode: text_at(Vector2(42,130),"JOURNAL / LOGS %d OF 3 / CREW %d OF 1" % [mission_log_count(game.mission_index),int(game.exploration.crew_rescued)],10,MUTED,true)
	text_at(Vector2(42,152),("CHASE / CLEARANCE COCKPIT" if game.player.chase_obstructed else ("CHASE VIEW" if game.player.chase_enabled else "COCKPIT VIEW"))+" / "+game.controls.label("camera_view"),10,MUTED,true)
	draw_flight_feedback()
	panel(Rect2(1215,30,345,113),0.6)
	text_at(Vector2(1235,56),"FLIGHT SCHOOL" if game.training_mode else "OPERATION / 0%d" % (game.mission_index+1),12,C,true)
	var objective=game.objective_text()
	text_at(Vector2(1235,86),objective,18,WHITE)
	for i in range(3):
		draw_rect(Rect2(1236+i*27,105,18,4),C if i < (int(game.training.step>=6)+int(game.training.step>=8)+int(game.training.finished) if game.training_mode else game.relays_down) else Color("3b5058"))
	text_at(Vector2(1330,114),"%02d / 11 CHECKS" % game.training.step if game.training_mode else "%d / 3 %s" % [game.relays_down,"RECOVERED" if game.mission_index==1 else "OFFLINE"],12,MUTED,true)
	# Heading ticks use the ship's orientation and remain valid during full rolls.
	var heading = fposmod(rad_to_deg(p.rotation.y),360)
	for i in range(-5,6):
		var x = 800+i*33
		line(Vector2(x,43),Vector2(x,49 if i%2 else 54),faint)
	text_at(Vector2(765,32),"%03d" % int(heading),15,C,true)
	line(Vector2(795,61),Vector2(800,66),C)
	line(Vector2(800,66),Vector2(805,61),C)
	# Reticle and pulse / missile readouts.
	var center = Vector2(800,450)
	var reticle_color = WHITE.lerp(C,game.hit_confirm)
	for side in [-1,1]:
		line(center+Vector2(side*12,-6),center+Vector2(side*20,-6),reticle_color,1.4)
		line(center+Vector2(side*20,-6),center+Vector2(side*20,6),reticle_color,1.4)
		line(center+Vector2(side*20,6),center+Vector2(side*12,6),reticle_color,1.4)
	draw_circle(center,1.5,C)
	if game.hit_confirm > 0:
		for side in [-1,1]:
			for up in [-1,1]: line(center+Vector2(side*25,up*25),center+Vector2(side*31,up*31),C,2)
	text_at(Vector2(720,508),game.arsenal.NAMES[p.primary_weapon],12,game.arsenal.COLORS[p.primary_weapon],true)
	text_at(Vector2(720,526),game.controls.label("next_weapon")+" / CYCLE PRIMARY",10,MUTED,true)
	if p.primary_weapon==2:
		meter(Vector2(720,535),p.rail_charge,160,A)
		if p.rail_charge>0.25: text_at(Vector2(720,614),"RELEASE FIRE / PIERCE",12,A,true)
	if not game.aim_name.is_empty():
		text_at(Vector2(720,548),game.aim_name,12,A,true)
		meter(Vector2(720,560),game.aim_health/game.aim_max,160,A)
		if game.seeker_lock: text_at(Vector2(741,592),"SEEKER LOCK",12,C,true)
	# Bottom instrument strip.
	panel(Rect2(40,788,330,78),0.72)
	text_at(Vector2(60,811),"SHIELD INTEGRITY",11,MUTED,true)
	text_at(Vector2(60,848),"%03d" % int(p.shield),31,C if p.shield>30 else A,true)
	meter(Vector2(139,831),p.shield/p.shield_max,205,C if p.shield>30 else A)
	panel(Rect2(390,788,250,78),0.72)
	text_at(Vector2(410,811),"WEAPON CAPACITOR",11,MUTED,true)
	text_at(Vector2(410,848),"%03d" % int(p.energy),29,C,true)
	meter(Vector2(486,831),p.energy/100,132,C)
	panel(Rect2(662,788,276,78),0.72)
	text_at(Vector2(682,812),"SEEKER MISSILES",11,MUTED,true)
	text_at(Vector2(682,847),"%02d" % p.missiles,30,A,true)
	text_at(Vector2(755,843),game.controls.label("missile")+" / LAUNCH",12,MUTED,true)
	panel(Rect2(960,788,244,78),0.72)
	text_at(Vector2(980,811),"AFTERBURNER",11,MUTED,true)
	meter(Vector2(980,832),p.boost/100,140,A)
	text_at(Vector2(1134,847),"%02d" % int(p.velocity.length()),22,WHITE,true)
	text_at(Vector2(1138,864),"M/S",9,MUTED,true)
	draw_radar(Vector2(1415,751),93)
	text_at(Vector2(42,890),"%s  FORWARD / %s  BOOST / %s  BRAKE / %s  MAP / %s  PAUSE" % [game.controls.label("forward"),game.controls.label("boost"),game.controls.label("brake"),game.controls.label("map"),game.controls.label("pause")],11,MUTED,true)
	text_at(Vector2(1280,890),"%02d:%02d  /  %05d PTS" % [int(game.mission_time)/60,int(game.mission_time)%60,game.score],11,C,true)
	draw_waypoints()
	if game.training_mode and not game.training.finished:
		panel(Rect2(430,215,740,112),0.92)
		text_at(Vector2(450,242),"CHECK %02d / 11   %s" % [game.training.step+1,game.training.STEPS[game.training.step]],15,A,true)
		wrapped(Vector2(450,273),game.training.instruction(),690,18,WHITE)
		meter(Vector2(450,312),float(game.training.step)/11,690,C)
	if game.kill_confirm>0: text_at(Vector2(728,631),"TARGET DESTROYED",14,A,true)
	if p.shield<p.shield_max*0.25 and int(game.clock*3)%2==0: text_at(Vector2(60,770),"WARNING / SHIELDS CRITICAL",13,A,true)
	if p.damage_flash>0 and not p.damage_direction.is_zero_approx():
		var local=p.camera.global_basis.inverse()*p.damage_direction
		var direction=Vector2(local.x,-local.y)
		if direction.length()<0.15: direction=Vector2(0,1 if local.z>0 else -1)
		var angle=direction.angle()
		draw_arc(Vector2(800,450),140,angle-0.22,angle+0.22,18,Color(1,0.35,0.2,p.damage_flash),5,true)
		if local.z>0: text_at(Vector2(761,668),"AFT DAMAGE",12,A,true)
	if game.notice_time > 0:
		var notice_y=275 if not game.exploration.radio_current.is_empty() and game.exploration.radio_time>0 else 151
		panel(Rect2(470,notice_y,660,55),0.75)
		wrapped(Vector2(490,notice_y+23),game.notice,620,14,A if game.reactor_down else C,true)
	if game.reactor_down:
		var color = A if int(game.clock*3)%2 == 0 else Color("ef715a")
		text_at(Vector2(695,254),["CONTAINMENT FAILURE","INTERCEPTORS INBOUND","FORTRESS COLLAPSE"][game.mission_index],14,color,true)
		text_at(Vector2(751,300),"%02d:%02d" % [int(game.escape_time)/60,int(game.escape_time)%60],34,color,true)
	if game.interaction_target>=0:
		text_at(Vector2(683,588),"HOLD "+game.controls.label("interact")+" / "+("UPLOAD" if game.targets[game.interaction_target].kind=="uplink" else "DOWNLOAD"),14,C,true)
		meter(Vector2(683,604),game.interaction_progress,234,C)
	if not game.training_mode and not game.reactor_down and game.is_secret_open() and p.position.distance_to(game.director.console_pos)<5 and game.director.challenge_state=="ready":
		text_at(Vector2(595,648),"HOLD "+game.controls.label("interact")+" / OPTIONAL COMBAT TRIAL",14,Color("b299ff"),true)
		meter(Vector2(595,665),game.director.interact_progress/2,410,Color("b299ff"))
	if not game.training_mode and not game.reactor_down and game.director.challenge_state=="active":
		text_at(Vector2(565,690),"COMBAT TRIAL / WAVE %d OF 2 / RETREAT IS OPEN" % game.director.wave,13,Color("b299ff"),true)
	if game.save_notice>0: text_at(Vector2(1270,168),"CHECKPOINT SAVED",12,C,true)
	var warden=null
	for d in game.drones:
		if d.role=="warden" and not d.dead and p.position.distance_to(d.position)<35: warden=d; break
	if warden!=null:
		text_at(Vector2(590,96),"WARDEN / "+("OVERDRIVE" if warden.enraged else "VAULT GUARDIAN"),14,Color("d4a6ff"),true)
		meter(Vector2(590,110),warden.health/warden.max_health,420,Color("d4a6ff"))
	elif is_instance_valid(game.boss) and not game.boss.dead and p.position.distance_to(game.boss.position)<75:
		text_at(Vector2(590,96),"THE OVERSEER / "+("SHIELDED" if game.relays_down<3 else "PHASE %d" % game.boss.phase),14,A,true)
		meter(Vector2(590,110),game.boss.health/game.boss.max_health,420,A)
	if p.damage_flash>0:
		draw_rect(Rect2(0,0,1600,900),Color(1,0.15,0.08,p.damage_flash*0.17))
	if game.flash>0: draw_rect(Rect2(0,0,1600,900),Color(1,0.72,0.45,game.flash*0.5))
	if not game.training_mode:
		draw_exploration()
		if game.systems.interacting:
			text_at(Vector2(570,648),"HOLD "+game.controls.label("interact")+" / LOCAL SECURITY OVERRIDE",13,game.systems.color,true)
			meter(Vector2(570,665),game.systems.progress/1.5,450,game.systems.color)
	if game.map_open: draw_map()

func meter(pos: Vector2,value: float,width: float,color: Color) -> void:
	for i in range(20):
		draw_rect(Rect2(pos+Vector2(i*width/20,0),Vector2(width/20-2,9)),color if float(i)/20 < value else Color("2a3e48"))

func draw_radar(pos: Vector2,radius: float) -> void:
	draw_circle(pos,radius,Color(0.025,0.06,0.08,0.8))
	draw_arc(pos,radius,0,TAU,64,Color(0.4,0.8,0.8,0.3),1,true)
	draw_arc(pos,radius*0.55,0,TAU,48,Color(0.4,0.8,0.8,0.12),1,true)
	line(pos-Vector2(radius,0),pos+Vector2(radius,0))
	line(pos-Vector2(0,radius),pos+Vector2(0,radius))
	for drone in game.drones:
		if not is_instance_valid(drone): continue
		var relative = game.player.global_basis.inverse()*(drone.position-game.player.position)
		if relative.length()>45: continue
		var point = Vector2(relative.x,relative.z)*2
		if point.length()<radius-8:
			draw_circle(pos+point,3,Color("ff8766"))
			line(pos+point,pos+point+Vector2(0,-clampf(relative.y,-8,8)),A)
	var arrow = PackedVector2Array([pos+Vector2(0,-7),pos+Vector2(-5,5),pos,pos+Vector2(5,5)])
	draw_colored_polygon(arrow,C)
	text_at(pos+Vector2(-59,radius+20),"PROXIMITY / 45M",11,MUTED,true)

func draw_waypoints() -> void:
	var points: Array = []
	if not game.nav_hint.is_empty(): points.append(game.nav_hint)
	if not game.reactor_down:
		for t in game.targets:
			if t.alive and (t.kind in ["relay","archive"] or game.relays_down==3):
				if not points.is_empty() and t.pos.distance_to(points[0].pos)<4: continue
				points.append({"pos":t.pos,"name":t.name,"color":C})
	if not game.training_mode: points.append_array(game.exploration.markers())
	var camera=game.player.camera
	var scale_to_design=Vector2(1600,900)/get_viewport_rect().size
	for i in range(points.size()):
		var point=points[i]
		var dist=game.player.position.distance_to(point.pos)
		if dist<1: continue
		var local=camera.global_basis.inverse()*(point.pos-camera.global_position)
		var behind=local.z>=-0.01
		if behind and i>0: continue
		var screen=Vector2.ZERO
		if not behind:
			screen=camera.unproject_position(point.pos)*scale_to_design
			var factor=1.0 if game.map_open else game.hud_scale
			screen=(screen-Vector2(800,450))/factor+Vector2(800,450)
		if behind:
			var direction=Vector2(local.x,-local.y)
			if direction.length()<0.1: direction=Vector2.DOWN
			screen=Vector2(800,450)+direction.normalized()*1000
		var offscreen=behind or screen.x<90 or screen.x>1350 or screen.y<230 or screen.y>690
		screen=screen.clamp(Vector2(90,340 if game.training_mode or game.exploration.radio_time>0 else 230),Vector2(1350,690))
		var color=point.color
		color.a=0.9 if i==0 else 0.42
		var r=9 if i==0 else 5
		var diamond=PackedVector2Array([screen+Vector2(0,-r),screen+Vector2(r,0),screen+Vector2(0,r),screen+Vector2(-r,0),screen+Vector2(0,-r)])
		draw_polyline(diamond,color,1.3,true)
		text_at(screen+Vector2(15,-4),point.name,12 if i==0 else 10,color,true)
		var height=point.pos.y-game.player.position.y
		text_at(screen+Vector2(15,13),"%d M%s%s" % [int(dist)," / TURN" if behind else "",(" / %+d ALT" % int(height)) if absf(height)>8 else ""],10,color,true)

func map_project(pos: Vector3) -> Vector2:
	return Vector2(850+pos.x*3.8+pos.z*1.3,660+pos.z*2.8-pos.y*3.6)

func draw_map() -> void:
	game.survey.draw(self)

func draw_overlay() -> void:
	if game.state=="won" and not game.training_mode:
		draw_debrief(); return
	draw_rect(Rect2(0,0,1600,900),Color(0.01,0.025,0.04,0.85))
	panel(Rect2(510,190,580,560),0.92)
	brand(Vector2(558,244),true)
	if game.state == "paused":
		text_at(Vector2(555,317),"FLIGHT SUSPENDED",35,WHITE)
		text_at(Vector2(555,724),"ESC / RESUME / CHECKPOINT ON EXIT",10,MUTED,true)
	else:
		text_at(Vector2(555,322),game.end_title,35,C if game.state=="won" else A)
		text_at(Vector2(555,364),game.end_detail,17,MUTED)
		line(Vector2(555,390),Vector2(1045,390))
		text_at(Vector2(555,430),"SCORE   %06d" % game.score,23,C,true)
		text_at(Vector2(555,468),"TRAINING CHECKS / 11 OF 11" if game.training_mode else "DRONES %02d / %02d   %s %d / 3" % [game.kills,game.total_drones,["RELAYS","ARCHIVES","NODES"][game.mission_index],game.relays_down],16,MUTED,true)
		text_at(Vector2(555,501),"FLIGHT  %02d:%02d     SECRET  %d / 1" % [int(game.mission_time)/60,int(game.mission_time)%60,int(game.secret_found)],16,MUTED,true)
		text_at(Vector2(555,532),"CERTIFICATION SAVED" if game.training_mode else "SALVAGE EARNED  +%d" % game.reward,18,A,true)

		if not game.training_mode and game.state=="won" and game.director.challenge_state=="cleared": text_at(Vector2(555,548),"OPTIONAL TRIAL BONUS / +300 SALVAGE INCLUDED",10,Color("b299ff"),true)

func draw_settings() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c"))
	if settings_tab=="controls":
		panel(Rect2(80,90,1440,750),0.96)
		text_at(Vector2(120,145),"CONTROL BINDINGS / "+binding_device.to_upper(),30,WHITE)
		var actions=game.controls.DEFAULTS.keys()
		for i in range(actions.size()):
			var origin=Vector2(120+(i/13)*730,250+(i%13)*35)
			text_at(origin+Vector2(0,23),game.controls.TITLES[actions[i]],17,MUTED)
		var message="PRESS AN INPUT FOR "+game.controls.TITLES[listening_action].to_upper()+" / ESC CANCELS" if not listening_action.is_empty() else game.controls.status
		text_at(Vector2(120,731),message if not message.is_empty() else "Duplicates are swapped. Keyboard, mouse, pad buttons and stick axes are supported.",14,A,true)
		return
	panel(Rect2(450,90,700,730),0.95)
	text_at(Vector2(500,145),"FLIGHT SETTINGS",33,WHITE)
	if settings_tab=="flight":
		for row in [["MOUSE SENSITIVITY","%.2f" % (game.player.sensitivity*1000)],["MASTER AUDIO","%d %%" % int(game.sound.volume*100)],["MUSIC","%d %%" % int(game.sound.music_volume*100)],["SOUND EFFECTS","%d %%" % int(game.sound.effects_volume*100)]]:
			var index=[["MOUSE SENSITIVITY","%.2f" % (game.player.sensitivity*1000)],["MASTER AUDIO","%d %%" % int(game.sound.volume*100)],["MUSIC","%d %%" % int(game.sound.music_volume*100)],["SOUND EFFECTS","%d %%" % int(game.sound.effects_volume*100)]].find(row)
			text_at(Vector2(500,246+index*70),row[0],14,C,true)
			text_at(Vector2(1020,246+index*70),row[1],14,MUTED,true)
		text_at(Vector2(500,656),"ASSIST BRAKES ON RELEASE / DRIFT RETAINS MOMENTUM",12,MUTED,true)
		text_at(Vector2(500,684),"F11 FULLSCREEN / SETTINGS AND BINDINGS AUTO-SAVE",12,MUTED,true)
	else:
		var rows=[["FIELD OF VIEW","%d DEG" % int(game.player.base_fov)],["HUD SIZE","%d %%" % int(game.hud_scale*100)],["CONTROLLER LOOK SPEED","%.2f" % game.player.controller_rate],["CONTROLLER DEADZONE","%d %%" % int(game.controls.deadzone*100)]]
		for i in range(4):
			text_at(Vector2(500,246+i*80),rows[i][0],14,C,true)
			text_at(Vector2(1010,246+i*80),rows[i][1],14,MUTED,true)
		text_at(Vector2(500,699),"PILOT 65% / STANDARD 100% / ACE 130% INCOMING DAMAGE",11,MUTED,true)

func build_settings() -> void:
	for i in range(3):
		var tab=["flight","display","controls"][i]
		button(tab.to_upper(),Vector2(500+i*205,175),Vector2(190,42),func(): settings_tab=tab; listening_action=""; rebuild_menu(),settings_tab==tab)
	if settings_tab=="controls":
		var actions=game.controls.DEFAULTS.keys()
		for i in range(actions.size()):
			var action=actions[i]
			var origin=Vector2(120+(i/13)*730,250+(i%13)*35)
			button("PRESS INPUT..." if listening_action==action else game.controls.label(action,binding_device),origin+Vector2(215,0),Vector2(370,30),func(): listening_action=action; rebuild_menu())
		button("BACK TO FLIGHT DECK",Vector2(120,770),Vector2(400,44),func(): settings_open=false; listening_action=""; rebuild_menu())
		button("RESTORE DEFAULT BINDINGS",Vector2(540,770),Vector2(400,44),func(): game.controls.reset(); game.save_settings(); rebuild_menu())
		button("EDIT "+("GAMEPAD" if binding_device=="keyboard" else "KEYBOARD / MOUSE"),Vector2(960,770),Vector2(440,44),func(): binding_device="controller" if binding_device=="keyboard" else "keyboard"; listening_action=""; rebuild_menu())
		return
	button("BACK TO FLIGHT DECK",Vector2(500,714),Vector2(600,52),func(): settings_open=false; rebuild_menu())
	if settings_tab=="flight":
		make_slider(Vector2(500,270),0.7,4.0,game.player.sensitivity*1000,func(value): game.player.sensitivity=value/1000)
		make_slider(Vector2(500,340),0,1,game.sound.volume,func(value): game.sound.set_volume(value))
		make_slider(Vector2(500,410),0,1,game.sound.music_volume,func(value): game.sound.music_volume=value)
		make_slider(Vector2(500,480),0,1,game.sound.effects_volume,func(value): game.sound.effects_volume=value)
		button("FLIGHT ASSIST: "+("ON" if game.player.flight_assist else "DRIFT"),Vector2(500,530),Vector2(290,40),func(): toggle_setting("flight_assist"))
		button("CAMERA SHAKE: "+("ON" if game.player.shake_enabled else "OFF"),Vector2(810,530),Vector2(290,40),func(): toggle_setting("shake_enabled"))
		button("INVERT LOOK: "+("ON" if game.player.invert_mouse else "OFF"),Vector2(500,586),Vector2(290,40),func(): toggle_setting("invert_mouse"))
		button("VIEW: "+("CHASE" if game.player.chase_enabled else "COCKPIT"),Vector2(810,586),Vector2(290,40),game.player.toggle_view)
	else:
		make_slider(Vector2(500,270),65,100,game.player.base_fov,func(value): game.player.base_fov=value)
		make_slider(Vector2(500,350),0.75,1,game.hud_scale,func(value): game.hud_scale=value)
		make_slider(Vector2(500,430),0.6,3.5,game.player.controller_rate,func(value): game.player.controller_rate=value)
		make_slider(Vector2(500,510),0.05,0.35,game.controls.deadzone,func(value): game.controls.deadzone=value; game.controls.apply())
		button("GRAPHICS / "+["PERFORMANCE","BALANCED","QUALITY"][game.graphics_preset],Vector2(500,570),Vector2(600,46),game.cycle_graphics)
		button("DIFFICULTY / "+["PILOT","STANDARD","ACE"][game.difficulty],Vector2(500,634),Vector2(600,46),game.cycle_difficulty)

func focus_first() -> void:
	if not is_instance_valid(ui) or game.state=="playing": return
	for control in ui.get_children():
		if control is Button and control.is_inside_tree() and not control.is_queued_for_deletion() and not control.disabled:
			control.grab_focus()
			return

func show_briefing() -> void:
	front_view="briefing"
	rebuild_menu()

func draw_briefing() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c"))
	brand(Vector2(100,70))
	var info=game.mission_info()
	text_at(Vector2(100,147),"OPERATION BRIEFING / 0%d" % (game.mission_index+1),18,info.color,true)
	text_at(Vector2(100,205),info.title,43,WHITE)
	wrapped(Vector2(100,267),info.brief,1180,24,MUTED)
	var steps=[
		["Disable the foundry, coolant and turbine relays.","Both reactor doors unlock when all relays are offline.","Destroy the reactor and return to the arrival dock within 75 seconds."],
		["Approach each archive and hold "+game.controls.label("interact")+" for two seconds.","Recover all three archives, then hold the interaction control at the uplink for three seconds.","Return to the dock within 90 seconds of uploading the evidence."],
		["Destroy the west, deep and crown shield nodes.","The crown shaft is above the boss chamber; you can enter while the Overseer is shielded.","Defeat three boss phases. Dodge the marked beam, then escape within 90 seconds."]][game.mission_index]
	for i in range(3):
		panel(Rect2(100,350+i*105,1190,85),0.85)
		text_at(Vector2(125,386+i*105),"0%d" % (i+1),24,info.color,true)
		wrapped(Vector2(190,385+i*105),steps[i],1060,21,WHITE)
	text_at(Vector2(100,690),"VAULT TRIALS ARE OPTIONAL / SHOOT HAZARD CELLS TO DISABLE / PULSE, PLASMA & RAIL SHARE ENERGY",12,info.color,true)
	text_at(Vector2(100,712),"SALVAGE FUNDS UPGRADES / GOLD DIAMOND GUIDES THE ROUTE / PAUSE TO SAVE AND EXIT",12,info.color,true)

func draw_credits() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c"))
	brand(Vector2(300,100))
	text_at(Vector2(300,177),"THE NEREID CAMPAIGN",40,WHITE)
	var rows=[["DESIGN & IMPLEMENTATION","The Subterranea project"],["ART & MODELS","Original Kestrel, drones, Overseer and procedural environments"],["MUSIC & SOUND","Original score / Kenney Sci-fi Sounds (CC0), mixed effects"],["ENGINE","Godot Engine 4.7.2 / MIT license"],["TYPE","Installed system fonts; no font files redistributed"],["INSPIRATION","Classic six-degrees-of-freedom combat flight"]]
	for i in range(rows.size()):
		text_at(Vector2(300,250+i*72),rows[i][0],13,C,true)
		text_at(Vector2(300,280+i*72),rows[i][1],22,MUTED)
	text_at(Vector2(300,715),"Godot and third-party license notices are included with the Windows release.",16,MUTED)

func toggle_setting(property: String) -> void:
	game.player.set(property,not game.player.get(property))
	game.save_settings()
	rebuild_menu()

func draw_flight_feedback() -> void:
	var p=game.player
	var center=Vector2(100,186)
	draw_arc(center,32,0,TAU,40,Color(0.4,0.8,0.8,0.2),1,true)
	var up=p.global_basis.inverse()*Vector3.UP
	var angle=atan2(up.x,up.y)
	var pitch=clampf((-p.global_basis.z).dot(Vector3.UP)*22,-22,22)
	var tangent=Vector2(cos(angle),sin(angle))*24
	var mid=center+Vector2(0,pitch)
	line(mid-tangent,mid+tangent,C,1.4)
	line(center-Vector2(7,0),center+Vector2(7,0),WHITE,2)
	text_at(Vector2(146,183),"%+04d M" % int(p.position.y),14,C,true)
	var mode="ASSIST" if p.flight_assist else "DRIFT"
	if p.braking: mode="AIRBRAKE"
	elif p.boosting: mode="AFTERBURNER"
	text_at(Vector2(146,206),mode,11,A if p.braking or p.boosting else MUTED,true)
	if p.boosting:
		for i in range(12):
			var theta=i*TAU/12+0.1
			var offset=fmod(game.clock*8+i*0.21,1)
			var start=Vector2(800,450)+Vector2(cos(theta)*790,sin(theta)*490)*(0.87+offset*0.1)
			var end=Vector2(800,450)+(start-Vector2(800,450))*1.08
			line(start,end,Color(0.4,0.9,0.9,0.15),1.3)

func wrapped(pos: Vector2,content: String,width: float,size_px: int,color: Color,technical: bool = false) -> void:
	var typeface=mono if technical else font
	var current=""
	var y=pos.y
	for word in content.split(" "):
		var candidate=current+word+" "
		if typeface.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x>width and not current.is_empty():
			text_at(Vector2(pos.x,y),current,size_px,color,technical)
			y+=size_px*1.4
			current=word+" "
		else: current=candidate
	text_at(Vector2(pos.x,y),current,size_px,color,technical)

func draw_campaign() -> void:
	draw_rect(Rect2(0,0,1600,900),Color(0.018,0.038,0.052,1))
	brand(Vector2(80,67))
	text_at(Vector2(80,137),"THE NEREID CAMPAIGN",38,WHITE)
	text_at(Vector2(1180,69),"SALVAGE / %05d" % game.campaign.data.salvage,20,A,true)
	for i in range(3):
		var mission=game.Progress.MISSIONS[i]
		var origin=Vector2(80+i*490,220)
		var unlocked=i<=game.campaign.data.unlocked
		var selected=i==game.mission_index
		var color=mission.color if unlocked else Color("526874")
		panel(Rect2(origin,Vector2(440,360)),0.92)
		draw_rect(Rect2(origin,Vector2(440,4)),color)
		if selected: draw_rect(Rect2(origin,Vector2(440,360)),color,false,2)
		text_at(origin+Vector2(30,55),"0%d" % (i+1),34,color,true)
		text_at(origin+Vector2(110,48),"CLEARED" if game.campaign.data.records[i].completed else ("AVAILABLE" if unlocked else "LOCKED"),13,color,true)
		wrapped(origin+Vector2(30,100),mission.title,380,26,WHITE if unlocked else MUTED)
		wrapped(origin+Vector2(30,169),mission.brief,380,17,MUTED)
		var record=game.campaign.data.records[i]
		if record.get("rank","--")!="--": text_at(origin+Vector2(350,55),str(record.rank),28,A,true)
		text_at(origin+Vector2(30,238),"BEST  %06d  /  RUNS %02d" % [record.best_score,record.runs],13,color,true)
		var fastest="%02d:%02d" % [int(record.best_time)/60,int(record.best_time)%60] if record.best_time>0 else "--:--"
		text_at(origin+Vector2(30,260),"FASTEST "+fastest+(" / SECRET FOUND" if record.secret else "")+(" / TRIAL CLEARED" if record.get("challenge",false) else ""),12,MUTED,true)
	text_at(Vector2(80,640),"SELECTED / "+game.mission_info().tag,20,C,true)
	wrapped(Vector2(80,680),game.mission_info().brief,1150,20,MUTED)
	text_at(Vector2(80,858),"MISSION REWARDS FUND PERMANENT SHIP UPGRADES. PROGRESS AND CHECKPOINTS AUTO-SAVE.",12,MUTED,true)
	if not game.campaign.last_error.is_empty(): wrapped(Vector2(80,185),game.campaign.last_error,1300,15,A)

func draw_workshop() -> void:
	draw_rect(Rect2(0,0,1600,900),Color(0.018,0.038,0.052,1))
	brand(Vector2(100,65))
	text_at(Vector2(100,132),"KESTREL / UPGRADE BAY",36,WHITE)
	text_at(Vector2(1160,75),"SALVAGE / %05d" % game.campaign.data.salvage,22,A,true)
	for i in range(4):
		var part=["shields","engines","cannons","missiles"][i]
		var definition=game.Progress.PARTS[part]
		var level=game.campaign.level(part)
		var origin=Vector2(100+(i%2)*715,190+(i/2)*270)
		panel(Rect2(origin,Vector2(650,245)),0.95)
		text_at(origin+Vector2(30,47),definition.title,27,C)
		for pip in range(3): draw_rect(Rect2(origin+Vector2(510+pip*30,30),Vector2(22,8)),C if pip<level else Color("314955"))
		text_at(origin+Vector2(30,86),definition.description,18,MUTED)
		var stats=""
		match part:
			"shields": stats="MAX SHIELDS  %d > %d" % [100+level*25,100+mini(3,level+1)*25]
			"engines": stats="BOOST SPEED  %.1f > %.1f M/S" % [25*(1+level*0.1),25*(1+mini(3,level+1)*0.1)]
			"cannons": stats="PULSE DAMAGE  %d > %d" % [18+level*4,18+mini(3,level+1)*4]
			"missiles": stats="BLAST DAMAGE  %d > %d / START %d" % [110+level*25,110+mini(3,level+1)*25,8+level*2]
		text_at(origin+Vector2(30,132),stats,16,A,true)
		if part=="cannons": text_at(origin+Vector2(30,156),"PLASMA %d > %d / FULL RAIL %d > %d" % [52+level*8,52+mini(3,level+1)*8,110+level*15,110+mini(3,level+1)*15],12,MUTED,true)
	text_at(Vector2(100,862),"THREE LEVELS PER SYSTEM. UPGRADES APPLY TO ALL OPERATIONS AND ARE SAVED IMMEDIATELY.",12,MUTED,true)
	if not game.campaign.last_error.is_empty(): wrapped(Vector2(100,165),game.campaign.last_error,1300,15,A)

func show_journal() -> void:
	journal_mission=game.mission_index; journal_radio=false; front_view="journal"; rebuild_menu()
func mission_log_count(index: int) -> int:
	var count=0
	for id in game.campaign.data.logs:
		if str(id).begins_with(str(index)+"_"): count+=1
	return count
func draw_exploration() -> void:
	var ex=game.exploration
	if ex.interacting:
		var label={"log":"DOWNLOAD RECORDER","pod":"SECURE CREW / LAUNCH COURIER","repair":"REPAIR COURIER"}.get(ex.candidate.get("kind",""),"INTERACT")
		text_at(Vector2(580,648),"HOLD "+game.controls.label("interact")+" / "+label,13,Color("8ff2c0"),true)
		meter(Vector2(580,665),ex.progress/1.5,440,Color("8ff2c0"))
	if ex.escort.status in ["following","waiting","disabled"]:
		panel(Rect2(42,280,280,105),0.72)
		text_at(Vector2(58,305),"RESCUE COURIER",14,Color("8ff2c0"),true)
		text_at(Vector2(58,329),ex.escort.status.to_upper()+" / %d M" % int(ex.escort.position.distance_to(game.player.position)),12,MUTED,true)
		meter(Vector2(58,344),ex.escort.integrity/160,240,Color("8ff2c0"))
		text_at(Vector2(58,371),"STAY WITHIN 20 M / REPAIR WITH INTERACT",9,MUTED,true)
	if ex.radio_time>0 and not ex.radio_current.is_empty():
		panel(Rect2(470,135,660,124),0.94)
		text_at(Vector2(490,160),ex.radio_current.speaker,13,C,true)
		wrapped(Vector2(490,189),ex.radio_current.text,620,16,WHITE)
func draw_journal() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c"))
	brand(Vector2(80,68)); text_at(Vector2(80,132),"MISSION JOURNAL / "+["NEREID","BOREAS","HELIOS"][journal_mission],35,WHITE)
	var entries=game.exploration.Lore.RADIO[journal_mission] if journal_radio else game.exploration.Lore.LOGS[journal_mission]
	var seen=game.campaign.data.radio if journal_radio else game.campaign.data.logs
	for index in range(entries.size()):
		var row=entries[index]; var id=row.id if journal_radio else str(journal_mission)+"_"+str(index)
		var y=245+index*(112 if journal_radio else 148)
		panel(Rect2(80,y,920,104 if journal_radio else 140),0.9)
		text_at(Vector2(100,y+28),((row.speaker if journal_radio else row.title.to_upper()) if id in seen else ("UNHEARD TRANSMISSION" if journal_radio else "RECORDER / "+row.hint.to_upper())),17,C if id in seen else MUTED)
		wrapped(Vector2(100,y+58),row.text if id in seen else ("Explore the operation to receive this transmission." if journal_radio else "Find and download this recorder to read its contents."),875,17,WHITE if id in seen else MUTED)
	panel(Rect2(1040,245,480,450),0.9)
	var record=game.campaign.data.records[journal_mission]
	var live=game.state=="paused" and journal_mission==game.mission_index and not game.training_mode
	var crew="EXTRACTED" if record.get("rescue",false) else ("ABOARD / EXTRACT TO RECORD" if live and game.exploration.crew_rescued else "NO EXTRACTION RECORDED")
	var courier="DELIVERED" if record.get("escort",false) else (game.exploration.escort.status.to_upper() if live and game.exploration.escort.status!="dormant" else "NO DELIVERY RECORDED")
	var vault=record.secret or (live and game.secret_found)
	var trial=record.get("challenge",false) or (live and game.director.challenge_state=="cleared")
	var rows=["DATA RECORDERS / %d OF 3" % mission_log_count(journal_mission),"SURVEY CACHE / "+("FOUND" if str(journal_mission)+"_cache" in game.campaign.data.caches else "UNDISCOVERED"),"CREW RESCUE / "+crew,"COURIER / "+courier,"RESERVE VAULT / "+("FOUND" if vault else "UNDISCOVERED"),"COMBAT TRIAL / "+("CLEARED" if trial else ("IN PROGRESS" if live and game.director.challenge_state=="active" else "NOT CLEARED"))]
	for i in range(rows.size()): text_at(Vector2(1062,285+i*48),rows[i],14,MUTED,true)
	wrapped(Vector2(1062,610),"Crew and courier records are awarded on successful extraction. Recorders, caches and paint discoveries save immediately.",430,16,C)
	text_at(Vector2(80,729),"DISCOVERIES PERSIST / OPTIONAL OBJECTIVES NEVER BLOCK THE MAIN MISSION",13,MUTED,true)
func draw_livery() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c"))
	panel(Rect2(70,45,650,790),0.95)
	brand(Vector2(110,100)); text_at(Vector2(110,168),"KESTREL / SHIP LIVERY",34,WHITE)
	text_at(Vector2(110,212),"SURVEY CACHE REWARDS / COSMETIC ONLY",13,C,true)
	for i in range(4):
		var row=game.exploration.Lore.PAINTS[i]
		text_at(Vector2(110,330+i*100),row.hint,15,MUTED)
	text_at(Vector2(890,765),game.exploration.paint().title,22,game.exploration.paint().accent,true)

func build_livery_stage() -> void:
	var container=SubViewportContainer.new(); container.position=Vector2(760,150); container.size=Vector2(760,550); container.stretch=true; container.mouse_filter=Control.MOUSE_FILTER_STOP; container.gui_input.connect(preview_input); ui.add_child(container)
	var viewport=SubViewport.new(); viewport.size=Vector2i(760,550); viewport.own_world_3d=true; viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; container.add_child(viewport)
	var world=WorldEnvironment.new(); var environment=Environment.new(); environment.background_mode=Environment.BG_COLOR; environment.background_color=Color("0b1a25"); environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; environment.ambient_light_color=Color("9ebac7"); environment.ambient_light_energy=0.65
	var sky=Sky.new(); var atmosphere=ProceduralSkyMaterial.new(); atmosphere.sky_top_color=Color("344b66"); atmosphere.sky_horizon_color=Color("b2c4cf"); atmosphere.ground_bottom_color=Color("101c2b"); atmosphere.ground_horizon_color=Color("677c8b"); sky.sky_material=atmosphere; environment.sky=sky; environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY; environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=environment; viewport.add_child(world)
	var stage=Node3D.new(); viewport.add_child(stage)
	var asset=FLEET[fleet_index].id if front_view=="fleet" else "kestrel"
	livery_model=load("res://assets/models/"+asset+".glb").instantiate(); stage.add_child(livery_model); livery_model.rotation.y=0.4
	var color=FLEET[fleet_index].color if front_view=="fleet" else game.exploration.paint().accent
	preload("res://scripts/ship_visuals.gd").attach(livery_model,asset,color)
	if asset=="kestrel": game.exploration.paint_meshes(livery_model)
	if front_view=="fleet": livery_model.scale=Vector3.ONE*({"kestrel":1.0,"scout":2.0,"striker":1.9,"bulwark":1.8,"warden":1.6,"overseer":0.54,"courier":2.4}.get(asset,1.0))
	preview_drag=false; preview_spin=true
	var key=DirectionalLight3D.new(); stage.add_child(key); key.rotation=Vector3(-0.7,-0.5,0); key.light_energy=1.35; key.shadow_enabled=true; key.directional_shadow_max_distance=25
	var fill=OmniLight3D.new(); stage.add_child(fill); fill.position=Vector3(-4,3,-1); fill.light_color=game.exploration.paint().accent; fill.light_energy=2; fill.omni_range=15
	var rim=OmniLight3D.new(); stage.add_child(rim); rim.position=Vector3(1,3,5); rim.light_color=Color("a5ccff"); rim.light_energy=3; rim.omni_range=16
	var plinth=MeshInstance3D.new(); var base=CylinderMesh.new(); base.top_radius=3.4; base.bottom_radius=3.5; base.height=0.16; base.radial_segments=96; plinth.mesh=base; stage.add_child(plinth); plinth.position.y=-1.17
	var finish=StandardMaterial3D.new(); finish.albedo_color=Color("1b2a36"); finish.metallic=0.15; finish.roughness=0.62; plinth.material_override=finish
	game.Forge.ring(stage,Vector3(0,-1.08,0),3.42,0.02,color,0.7)
	preview_camera=Camera3D.new(); stage.add_child(preview_camera); preview_camera.position=Vector3(4.4,3.4,-6.8); preview_camera.look_at(Vector3.ZERO); preview_camera.fov=50; preview_camera.current=true
	for i in range(4): button(["FRONT","REAR","SIDE","AUTO ROTATE"][i],Vector2(770+i*190,708),Vector2(180,38),func(): preview_view(i))

func show_saves() -> void:
	front_view="saves"; save_message=""; confirm_slot=-1; confirm_load=-1; rebuild_menu()
func request_slot_save(index: int) -> void:
	if not game.campaign.data.manual_slots[index].is_empty() and confirm_slot!=index:
		confirm_slot=index; confirm_load=-1; save_message="Click CONFIRM OVERWRITE to replace that manual slot."; rebuild_menu(); return
	game.manual_save(index)
func request_slot_load(index: int) -> void:
	if confirm_load!=index:
		confirm_load=index; confirm_slot=-1; save_message="Loading replaces the current run. Profile upgrades, discoveries and earned rewards stay intact."; rebuild_menu(); return
	game.manual_load(index)
func draw_saves() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c")); brand(Vector2(80,68))
	text_at(Vector2(80,132),"PILOT %d / SAVES" % (game.profile_store.active+1),35,WHITE)
	text_at(Vector2(80,285),"AUTOSAVE IS SEPARATE / THREE MANUAL SLOTS PER PROFILE / SAVE FROM PAUSE",13,MUTED,true)
	for i in range(3):
		var y=310+i*135; panel(Rect2(80,y,1440,110),0.9)
		var entry=game.campaign.data.manual_slots[i]
		text_at(Vector2(100,y+30),"MANUAL SLOT %d" % (i+1),18,C,true)
		if entry.is_empty(): text_at(Vector2(100,y+70),"EMPTY",19,MUTED)
		else:
			var run=entry.checkpoint; var seconds=int(run.get("time",0))
			text_at(Vector2(100,y+63),game.Progress.MISSIONS[int(run.mission)].title,21,WHITE)
			var claimed=str(run.get("run","")) in game.campaign.data.claimed_runs
			text_at(Vector2(100,y+91),"FLIGHT %02d:%02d / SHIELDS %03d / %s" % [seconds/60,seconds%60,int(run.pilot.get("shield",100)),"REWARD ALREADY CLAIMED" if claimed else "UNCLAIMED RUN"],12,MUTED,true)
	wrapped(Vector2(80,750),save_message if not save_message.is_empty() else ("Return to the flight deck before switching profiles. Manual saves preserve the current mission; they do not rewind profile upgrades or discoveries." if game.state=="paused" else "Manual saves load mission progress. Permanent upgrades, discoveries and completed-run rewards are retained."),1420,16,A if not save_message.is_empty() else MUTED)
func draw_profiles() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c")); brand(Vector2(80,68)); text_at(Vector2(80,132),"CAMPAIGN PROFILES",35,WHITE)
	for row in profile_rows:
		var x=80+row.index*490; panel(Rect2(x,225,440,400),0.9)
		text_at(Vector2(x+30,280),"PILOT %d" % (row.index+1),30,C if row.active else WHITE)
		text_at(Vector2(x+30,325),"ACTIVE" if row.active else ("EXISTING CAMPAIGN" if row.exists else "EMPTY PROFILE"),14,C,true)
		text_at(Vector2(x+30,382),"OPERATIONS %d / 3" % row.unlocked,18,MUTED,true)
		text_at(Vector2(x+30,425),"SALVAGE %05d" % row.salvage,18,A,true)
		text_at(Vector2(x+30,468),"RUNS %02d / %s" % [row.runs,"AUTOSAVE" if row.checkpoint else "NO AUTOSAVE"],14,MUTED,true)
	wrapped(Vector2(80,685),"Pilot 1 preserves the existing campaign file. Each profile owns its campaign, upgrades, discoveries, autosave and manual slots. Flight and audio settings are shared.",1420,18,MUTED)
	if not save_message.is_empty(): text_at(Vector2(80,735),save_message,16,A)
func draw_debrief() -> void:
	draw_rect(Rect2(0,0,1600,900),Color(0.01,0.025,0.04,0.9)); panel(Rect2(360,100,880,700),0.96)
	brand(Vector2(400,143),true); text_at(Vector2(400,200),game.end_title,35,C)
	wrapped(Vector2(400,239),game.end_detail,780,17,MUTED)
	text_at(Vector2(400,300),"SCORE %06d / FLIGHT %02d:%02d" % [game.score,int(game.mission_time)/60,int(game.mission_time)%60],21,C,true)
	text_at(Vector2(400,344),"SALVAGE EARNED +%d" % game.reward,21,A,true)
	text_at(Vector2(1070,308),str(game.rating.get("rank","--")),62,A,true)
	var categories=["combat","exploration","rescue","escape"]
	for i in range(4):
		var x=400+i*205; var grade=int(game.rating.get("medals",{}).get(categories[i],0))
		panel(Rect2(x,385,185,115),0.95)
		var color=[MUTED,Color("c9966f"),Color("cad9e3"),Color("ffe09b")][grade]
		text_at(Vector2(x+15,416),categories[i].to_upper(),13,MUTED,true)
		text_at(Vector2(x+15,460),game.Ratings.TIERS[grade],22,color,true)
	text_at(Vector2(400,532),"BEST MEDALS AND HIGHEST OVERALL RANK SAVE TO THIS PROFILE",11,MUTED,true)
	text_at(Vector2(400,762),"REPLAY TO IMPROVE COMBAT COVERAGE, SURVEY COMPLETION, RESCUE INTEGRITY AND ESCAPE RESERVE",10,MUTED,true)

func draw_fleet() -> void:
	draw_rect(Rect2(0,0,1600,900),Color("07131c")); panel(Rect2(70,45,650,790),0.95)
	brand(Vector2(110,100)); text_at(Vector2(110,168),"FLEET HANGAR",34,WHITE)
	text_at(Vector2(110,212),"VESSEL RECOGNITION / SEVEN DISTINCT HULLS",13,C,true)
	text_at(Vector2(790,790),FLEET[fleet_index].name,24,FLEET[fleet_index].color)
	wrapped(Vector2(790,824),FLEET[fleet_index].info,700,17,MUTED)
	text_at(Vector2(790,130),"DRAG TO ROTATE / WHEEL TO ZOOM",13,MUTED,true)
func preview_input(event: InputEvent) -> void:
	if not is_instance_valid(livery_model) or not is_instance_valid(preview_camera): return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			preview_drag=event.pressed
			if event.pressed: preview_spin=false
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var distance=preview_camera.position.length()*(0.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1)
			preview_camera.position=preview_camera.position.normalized()*clampf(distance,5.5,16)
			preview_camera.look_at(Vector3.ZERO)
	elif event is InputEventMouseMotion and preview_drag:
		livery_model.rotation.y+=event.relative.x*0.009
		livery_model.rotation.x=clampf(livery_model.rotation.x+event.relative.y*0.006,-0.8,0.8)
func preview_view(index: int) -> void:
	if not is_instance_valid(preview_camera): return
	preview_spin=index==3; preview_drag=false; livery_model.rotation=Vector3.ZERO
	preview_camera.position=[Vector3(0,1.5,-10),Vector3(0,2.0,10),Vector3(10,2.5,0),Vector3(4.4,3.4,-6.8)][index]
	preview_camera.look_at(Vector3.ZERO)
