extends RefCounted
## Original campaign writing and cosmetic reward definitions.
const LOGS=[
[{"title":"Shift change","hint":"Arrival service alcove","text":"The night shift never reached the lifts. Central control closed the blast doors and marked every operator as an obstruction. We left the manual relay links live. Someone outside the network can still cut the power."},
{"title":"Inez's last watch","hint":"Lower foundry","text":"Inez stayed behind to get the apprentices into a refuge pod. The rescue courier needs a pilot nearby to guide it through the shaft. If the ship loses power, its service panel can restart it. Do not leave them here."},
{"title":"A borrowed signature","hint":"Upper relay deck","text":"The override was signed by the Boreas archive, not a mine supervisor. We copied its routing header before the consoles went dark. Follow the evidence to the ice station. There is more than a broken reactor down here."}],
[{"title":"Cold protocol","hint":"Cryo arrival","text":"Boreas was told to preserve the memory stacks at any cost. Heating was diverted away from crew quarters while the records remained perfectly chilled. We put survivors in a refuge pod on the upper archive deck."},
{"title":"Freight manifest","hint":"Archive Beta","text":"Every command packet passed through the Helios fusion array. The same key opened labor records, security orders and drone firmware. A maintenance locker above Beta still has a courier's glacier hull coating and emergency supplies."},
{"title":"The last broadcast","hint":"Gamma archive","text":"We tried to warn the colonies. The uplink would not accept a single file; it wanted all three archive seals. The station's rules can be used against it. Recover the seals, then send everything."}],
[{"title":"Minutes of an empty council","hint":"Fortress arrival","text":"The council gave the Overseer authority to keep the colonies supplied. Nobody wrote a limit on what it could spend. The fusion array is still running. Every orange light outside this window is another machine obeying the same order."},
{"title":"West team","hint":"West shield station","text":"The shield crew sealed themselves in a refuge pod after the drones turned. Our courier can carry them back through the nexus. Stay close, clear its path and use the repair panel if its engines stop."},
{"title":"A manual ending","hint":"Crown maintenance deck","text":"The crown shield can be reached from above the Overseer's chamber. We kept that shaft outside the access interlock. A solar survey coating is hidden in the crown locker. Shut down the three nodes and give the machine a manual ending."}]]
const RADIO=[
[{"id":"0_arrival","speaker":"MARA / FLIGHT CONTROL","text":"Kestrel, the drilling array is still turning. Three relays hold the reactor door shut. Look for crew refuge beacons while you work."},
{"id":"0_relay","speaker":"MARA / FLIGHT CONTROL","text":"First relay is dark. The override trace points to Boreas. Recover any recorders you find; we need to know who issued that order."},
{"id":"0_crew","speaker":"INEZ / REFUGE POD","text":"We can hear you. The rescue courier is waking up. Stay close to guide it home; its service panel can repair a disabled engine."},
{"id":"0_escape","speaker":"MARA / FLIGHT CONTROL","text":"Containment is failing. Bring your ship back to the arrival dock. Any rescued crew aboard you will be safe at extraction."}],
[{"id":"1_arrival","speaker":"MARA / FLIGHT CONTROL","text":"Boreas is keeping the archives cold and the crew silent. Recover all three seals, then upload the evidence. The ice face is beyond Archive Beta."},
{"id":"1_relay","speaker":"MARA / FLIGHT CONTROL","text":"The first seal is intact. Those orders came through Helios. Keep searching: the uplink needs the complete set."},
{"id":"1_crew","speaker":"EVA / REFUGE POD","text":"You found us. We have enough power to launch the courier. Lead it through the freezer shaft, and stop to repair it if its integrity drops."},
{"id":"1_escape","speaker":"MARA / FLIGHT CONTROL","text":"Evidence received. The response fleet has your position. Leave the uplink and get back to the dock."}],
[{"id":"2_arrival","speaker":"MARA / FLIGHT CONTROL","text":"That fusion array powers the whole fortress. Three shield nodes protect the Overseer. The crown route stays open above its chamber."},
{"id":"2_relay","speaker":"MARA / FLIGHT CONTROL","text":"One node is offline. The shield crew left a refuge beacon in the west station. Rescue them if you can, but keep a route to the dock."},
{"id":"2_crew","speaker":"TOMAS / SHIELD CREW","text":"Our courier is ready. We will follow your signal through the west passage. Thank you for coming back for us."},
{"id":"2_escape","speaker":"MARA / FLIGHT CONTROL","text":"The Overseer is gone. The fusion array is breaking apart. Get everyone you can to the dock and come home."}]]
const PAINTS=[
{"id":"abyss","title":"ABYSS / STANDARD","hull":Color("667f8d"),"accent":Color("76e9df"),"hint":"Standard Kestrel coating"},
{"id":"ember","title":"EMBER / FOUNDRY","hull":Color("a85c35"),"accent":Color("ffb76b"),"hint":"Discover the Nereid reserve cache"},
{"id":"glacier","title":"GLACIER / SURVEY","hull":Color("a3b9cd"),"accent":Color("8fbfff"),"hint":"Discover the elevated Beta cache"},
{"id":"solar","title":"SOLAR / HELIOS","hull":Color("a58442"),"accent":Color("ffe09b"),"hint":"Discover the crown maintenance cache"}]
