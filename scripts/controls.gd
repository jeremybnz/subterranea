extends RefCounted
## Keyboard, mouse and gamepad share one action map. Rebinding swaps conflicts.
const DEFAULTS={"forward":["key",KEY_W],"reverse":["key",KEY_S],"left":["key",KEY_A],"right":["key",KEY_D],"up":["key",KEY_SPACE],"down":["key",KEY_CTRL],"roll_left":["key",KEY_Q],"roll_right":["key",KEY_E],"boost":["key",KEY_SHIFT],"brake":["key",KEY_C],"fire":["mouse",MOUSE_BUTTON_LEFT],"missile":["mouse",MOUSE_BUTTON_RIGHT],"interact":["key",KEY_R],"map":["key",KEY_TAB],"light":["key",KEY_F],"pause":["key",KEY_ESCAPE],"look_left":["key",KEY_LEFT],"look_right":["key",KEY_RIGHT],"look_up":["key",KEY_UP],"look_down":["key",KEY_DOWN],"next_weapon":["key",KEY_V],"pulse_weapon":["key",KEY_1],"plasma_weapon":["key",KEY_2],"rail_weapon":["key",KEY_3],"camera_view":["key",KEY_T]}
const PAD_DEFAULTS={"forward":["axis",JOY_AXIS_LEFT_Y,-1],"reverse":["axis",JOY_AXIS_LEFT_Y,1],"left":["axis",JOY_AXIS_LEFT_X,-1],"right":["axis",JOY_AXIS_LEFT_X,1],"up":["button",JOY_BUTTON_A],"down":["button",JOY_BUTTON_B],"roll_left":["button",JOY_BUTTON_LEFT_SHOULDER],"roll_right":["button",JOY_BUTTON_RIGHT_SHOULDER],"boost":["button",JOY_BUTTON_LEFT_STICK],"brake":["button",JOY_BUTTON_RIGHT_STICK],"fire":["axis",JOY_AXIS_TRIGGER_RIGHT,1],"missile":["axis",JOY_AXIS_TRIGGER_LEFT,1],"interact":["button",JOY_BUTTON_X],"map":["button",JOY_BUTTON_BACK],"light":["button",JOY_BUTTON_Y],"pause":["button",JOY_BUTTON_START],"look_left":["axis",JOY_AXIS_RIGHT_X,-1],"look_right":["axis",JOY_AXIS_RIGHT_X,1],"look_up":["axis",JOY_AXIS_RIGHT_Y,-1],"look_down":["axis",JOY_AXIS_RIGHT_Y,1],"next_weapon":["button",JOY_BUTTON_DPAD_RIGHT],"pulse_weapon":["button",JOY_BUTTON_DPAD_UP],"plasma_weapon":["button",JOY_BUTTON_DPAD_LEFT],"rail_weapon":["button",JOY_BUTTON_DPAD_DOWN],"camera_view":["button",JOY_BUTTON_TOUCHPAD]}
const TITLES={"forward":"Forward","reverse":"Reverse","left":"Strafe left","right":"Strafe right","up":"Rise","down":"Descend","roll_left":"Roll left","roll_right":"Roll right","boost":"Afterburner","brake":"Airbrake","fire":"Primary fire / charge","missile":"Seeker missile","interact":"Interact / download","map":"Tactical map","light":"Headlight","pause":"Pause","look_left":"Look left","look_right":"Look right","look_up":"Look up","look_down":"Look down","next_weapon":"Cycle primary","pulse_weapon":"Select pulse","plasma_weapon":"Select plasma","rail_weapon":"Select railgun","camera_view":"Cockpit / chase view"}
var bindings=DEFAULTS.duplicate(true)
var pad_bindings=PAD_DEFAULTS.duplicate(true)
var deadzone=0.18
var last_device="keyboard"
var status=""

func _init() -> void: apply()
func make_event(value: Array) -> InputEvent:
	match str(value[0]):
		"key":
			var event=InputEventKey.new()
			event.physical_keycode=int(value[1])
			return event
		"mouse":
			var event=InputEventMouseButton.new()
			event.button_index=int(value[1])
			return event
		"button":
			var event=InputEventJoypadButton.new()
			event.device=-1
			event.button_index=int(value[1])
			return event
		"axis":
			var event=InputEventJoypadMotion.new()
			event.device=-1
			event.axis=int(value[1])
			event.axis_value=float(value[2])
			return event
	return null
func valid(value: Variant,pad: bool) -> bool:
	if not value is Array or value.size()<2 or not value[1] is int: return false
	if pad:
		return (value[0]=="button" and value[1] in range(22)) or (value[0]=="axis" and value.size()==3 and value[1] in range(6) and int(value[2]) in [-1,1])
	return (value[0]=="key" and value[1]>0) or (value[0]=="mouse" and value[1] in [1,2,3,8,9])
func apply() -> void:
	# Godot supplies directional pad navigation, but acceptance/cancel need explicit pad events.
	for mapping in [["ui_accept",JOY_BUTTON_A],["ui_cancel",JOY_BUTTON_B]]:
		var event=make_event(["button",mapping[1]])
		if not InputMap.action_has_event(mapping[0],event): InputMap.action_add_event(mapping[0],event)
	for action in DEFAULTS:
		var name="ship_"+action
		if not InputMap.has_action(name): InputMap.add_action(name,deadzone)
		Input.action_release(name)
		InputMap.action_erase_events(name)
		InputMap.action_set_deadzone(name,deadzone)
		InputMap.action_add_event(name,make_event(bindings[action]))
		InputMap.action_add_event(name,make_event(pad_bindings[action]))
func load_bindings(keys: Variant,pad: Variant) -> void:
	bindings=DEFAULTS.duplicate(true); pad_bindings=PAD_DEFAULTS.duplicate(true)
	install_saved(bindings,keys,false)
	install_saved(pad_bindings,pad,true)
	apply()
func install_saved(table: Dictionary,saved: Variant,pad: bool) -> void:
	if not saved is Dictionary: return
	for action in DEFAULTS:
		var value=saved.get(action,null)
		if not valid(value,pad): continue
		var previous=table[action]
		for other in table:
			if other!=action and table[other]==value: table[other]=previous; break
		table[action]=value
func reset() -> void:
	bindings=DEFAULTS.duplicate(true)
	pad_bindings=PAD_DEFAULTS.duplicate(true)
	status="Default controls restored"
	apply()
func strength(action: String) -> float: return Input.get_action_strength("ship_"+action)
func held(action: String) -> bool: return Input.is_action_pressed("ship_"+action)
func axis(negative: String,positive: String) -> float: return Input.get_axis("ship_"+negative,"ship_"+positive)
func pressed(event: InputEvent,action: String) -> bool: return event.is_action_pressed("ship_"+action,false,event is InputEventJoypadMotion)
func observe(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed: last_device="controller"
	elif event is InputEventJoypadMotion and absf(event.axis_value)>deadzone+0.1: last_device="controller"
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length()>2): last_device="keyboard"
func bind_event(action: String,event: InputEvent,pad: bool) -> bool:
	if not DEFAULTS.has(action): return false
	var value: Array=[]
	if pad:
		if event is InputEventJoypadButton and event.pressed: value=["button",event.button_index]
		elif event is InputEventJoypadMotion and absf(event.axis_value)>0.75: value=["axis",event.axis,1 if event.axis_value>0 else -1]
	else:
		if event is InputEventKey and event.pressed and not event.echo:
			var key=event.physical_keycode if event.physical_keycode else event.keycode
			if key in [KEY_ENTER,KEY_KP_ENTER,KEY_F11,KEY_ESCAPE]: status="That key is reserved for menus"; return false
			value=["key",key]
		elif event is InputEventMouseButton and event.pressed and event.button_index in [1,2,3,8,9]: value=["mouse",event.button_index]
	if value.is_empty(): return false
	var table=pad_bindings if pad else bindings
	var old=table[action]
	for other in table:
		if other!=action and table[other]==value:
			table[other]=old
			break
	table[action]=value
	status="Bound "+TITLES[action]+" to "+label(action,"controller" if pad else "keyboard")
	apply()
	return true
func label(action: String,device: String = "") -> String:
	var mode=last_device if device.is_empty() else device
	var value=pad_bindings[action] if mode=="controller" else bindings[action]
	match value[0]:
		"key": return OS.get_keycode_string(int(value[1])).to_upper()
		"mouse": return {1:"LEFT MOUSE",2:"RIGHT MOUSE",3:"MIDDLE MOUSE",8:"MOUSE 4",9:"MOUSE 5"}.get(int(value[1]),"MOUSE")
		"button": return {0:"A / CROSS",1:"B / CIRCLE",2:"X / SQUARE",3:"Y / TRIANGLE",4:"BACK / SHARE",6:"START / OPTIONS",7:"LEFT STICK CLICK",8:"RIGHT STICK CLICK",9:"LB / L1",10:"RB / R1",11:"D-PAD UP",12:"D-PAD DOWN",13:"D-PAD LEFT",14:"D-PAD RIGHT",20:"TOUCHPAD"}.get(int(value[1]),"PAD BUTTON %d" % value[1])
		"axis":
			if int(value[1])==JOY_AXIS_TRIGGER_LEFT: return "LT / L2"
			if int(value[1])==JOY_AXIS_TRIGGER_RIGHT: return "RT / R2"
			var horizontal=int(value[1]) in [JOY_AXIS_LEFT_X,JOY_AXIS_RIGHT_X]
			var direction=("LEFT" if value[2]<0 else "RIGHT") if horizontal else ("UP" if value[2]<0 else "DOWN")
			return ("LEFT STICK " if int(value[1])<2 else "RIGHT STICK ")+direction
	return "UNBOUND"
