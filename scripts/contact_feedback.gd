extends RefCounted
const COLORS={"metal":Color("ffc18b"),"glass":Color("b5efff"),"shield":Color("83eaff"),"armor":Color("ffbd68"),"hull":Color("ff976c"),"objective":Color("a2f1cf")}
var game
var next_sound={}
var last_surface=""
var last_position=Vector3.ZERO
func _init(owner): game=owner
func classify(body: Object,weapon: String,origin: Vector3) -> String:
	if body.has_meta("surface"): return str(body.get_meta("surface"))
	if body is CollisionObject3D and body.collision_layer & 16: return "metal"
	if body.has_meta("target_id"):
		var target=game.targets[int(body.get_meta("target_id"))]
		if not game.training_mode and target.kind=="reactor" and game.relays_down<3: return "shield"
		return "objective"
	if body.has_method("hit") and body.get("max_health")!=null:
		if body==game.boss and (game.relays_down<3 or game.boss.warming>0): return "shield"
		if body.get("elite") and weapon in ["pulse","enemy"] and origin.is_finite() and (-body.visual.global_basis.z).dot((origin-body.global_position).normalized())>0.6: return "armor"
		return "shield" if float(body.health)>float(body.max_health)*0.5 else "hull"
	return "metal"
func play(hit: Dictionary,weapon: String,origin: Vector3) -> String:
	if hit.is_empty(): return ""
	var surface=classify(hit.collider,weapon,origin); last_surface=surface; last_position=hit.position
	var color=COLORS.get(surface,COLORS.metal)
	game.impact(hit.position,color,3 if weapon=="pulse" else 5)
	if game.clock>=float(next_sound.get(surface,-1)):
		next_sound[surface]=game.clock+0.055
		var voice=game.sound.play_at("shield_hit" if surface=="shield" else "hit",hit.position,0.26 if weapon=="enemy" else 0.4)
		if is_instance_valid(voice):
			voice.pitch_scale*=1.65 if surface=="glass" else (0.75 if surface=="armor" else (0.9 if surface=="hull" else 1.0))
			voice.set_meta("surface",surface)
	return surface
