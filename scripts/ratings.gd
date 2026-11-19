extends RefCounted
const TIERS=["NONE","BRONZE","SILVER","GOLD"]
static func tier(value: float) -> int:
	return 3 if value>=0.9 else (2 if value>=0.6 else (1 if value>=0.3 else 0))
static func evaluate(game) -> Dictionary:
	var combat=tier(float(game.kills)/maxi(1,game.total_drones))
	var coverage=float(game.survey.seen.size())/maxi(1,game.map_rooms.size())
	var logs=0
	for id in game.campaign.data.logs:
		if str(id).begins_with(str(game.mission_index)+"_"): logs+=1
	var exploration=tier(coverage*0.6+float(logs)/3*0.4)
	var rescue=0
	if game.exploration.crew_rescued: rescue=1
	if game.exploration.escort.status=="delivered": rescue=3 if game.exploration.escort.integrity>=100 else 2
	var reserve=game.escape_time/game.mission_info().escape
	var escape=3 if reserve>=0.7 else (2 if reserve>=0.4 else 1)
	var medals={"combat":combat,"exploration":exploration,"rescue":rescue,"escape":escape}
	var total=combat+exploration+rescue+escape
	var rank="S" if total==12 else ("A" if total>=9 else ("B" if total>=6 else ("C" if total>=3 else "D")))
	return {"medals":medals,"rank":rank,"points":total,"coverage":coverage,"kills":game.kills,"escape_reserve":reserve}
