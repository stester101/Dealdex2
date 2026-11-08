extends RefCounted
## Map scripts and cutscenes. World.run_script(id) calls run(id, world, actor).


func run(id: String, W: World, who: Actor) -> void:
	var M = Game.main
	match id:
		"intro":
			await _intro(W)
		"kettle_ferry":
			if not Game.flag("starter"):
				return
			await M.say(["We dock in Amsterdam soon.", "Your strains look tired. Hold on..."], "KETTLE")
			await _heal()
			if await M.ask("Ready to go ashore?", "KETTLE"):
				await _arrival(W)
			else:
				await M.say(["No rush. The cargo nets are full of stowaways. Go and catch something."], "KETTLE")
		"oli_ferry":
			await M.say(["Next time I'm taking the good one.", "Remind me: 29 is key."], "OLI")
		"tourist_ferry":
			await M.say(["First time on a ferry?", "Don't look at the water. Don't think about the water."], "TOURIST")
		"oldman_ferry":
			await M.say(["Forty years I've done this crossing.", "Never once seen a strain on board. Until today. Now there's dozens."], "OLD SALT")
		"kettle_quay":
			await M.say(["Amsterdam! Lovely.", "Let me patch your strains up first."], "KETTLE")
			await _heal()
			await M.say(["The Bullfrog is the first gym. It opens tomorrow.", "That's the end of the opening, mate. The next build carries on from here."], "KETTLE")
			if await M.ask("Save your progress?"):
				Game.save_game()
				Sfx.play("confirm")
				await M.say(["Progress saved."])
		"oli_quay":
			await M.say(["They say the Bullfrog's leader has never lost at home.", "Agent of chill. Total legend."], "OLI")
		"tourist_quay":
			await M.say(["Is this the famous red district?", "...Oh. It's just the lamps."], "TOURIST")
		"cyclist":
			await M.say(["BELL! BELL! Fietspad!", "Sorry. Force of habit.", "Wild strains love the planters in the park. Over the bridge."], "CYCLIST")
		"oldman_quay":
			await M.say(["I feed the Coo-Kush every evening.", "They are not grateful. They are never grateful."], "OLD MAN")
		"local_quay":
			await M.say(["Grachtlings rise out of the canal at dusk.", "You picked a good time to arrive."], "LOCAL")
		"clerk":
			await M.say(["Welcome to Hostel Het Kanaal."], "CLERK")
			if await M.ask("Rest your strains? Free for guests.", "CLERK"):
				await M.fade_out(0.3)
				Game.heal_all()
				Sfx.jingle("heal")
				await M.get_tree().create_timer(1.2).timeout
				Sfx.music("music_quay")
				await M.fade_in(0.3)
				Game.state.heal_map = "hostel"
				Game.state.heal_x = 4
				Game.state.heal_y = 4
				await M.say(["Your strains are fully rested."], "CLERK")
		"bullfrog_door":
			await M.say(["THE BULLFROG - COFFEESHOP & GYM", "A note on the door: CLOSED. Gym opens tomorrow. No stress on the bless.", "(The first gym arrives in the next build.)"])
		"edge_quay":
			await M.say(["The rest of Amsterdam opens in the next build."])
		_:
			if id != "":
				await M.say(["..."])


func _heal() -> void:
	Game.heal_all()
	Sfx.play("heal")
	await Game.main.flash(Color(1, 1, 1, 0.6), 0.25)


func _intro(W: World) -> void:
	var M = Game.main
	await M.say(["THE CROSSING. 06:40.", "Dover is a smudge behind you. Amsterdam is somewhere ahead.", "The whole group is on this boat. Somewhere."])
	var k = W.spawn_npc("kettle", "kettle", Vector2i(11, 12), 0, "kettle_ferry")
	Sfx.play("door")
	await k.walk_path([0, 0, 0])
	W.player.face(3)
	await k.show_emote(0.5)
	await M.say(["There you are!", "Remind me: what are we doing in Amsterdam again?", "Doesn't matter. Look what I got through Dover.", "Three strains. Fresh from the bulb fields. Don't tell customs.", "Pick one. It's yours for the trip."], "KETTLE")
	var sp: String = await M.pick_starter()
	var mon = Game.mk_mon(sp, 5)
	Game.state.party.append(mon)
	Game.mark_caught(sp)
	Game.set_flag("met_kettle")
	Game.set_flag("starter")
	Sfx.play("caught")
	await M.say(["You received %s!" % Data.SPECIES[sp].name, "Nice. Look after it."], "")
	# rival arrives
	var o = W.spawn_npc("oli", "oli", Vector2i(18, 16), 1, "oli_ferry")
	await o.walk_path([1, 1, 1, 1, 1, 1])
	W.player.face(2)
	await o.show_emote(0.5)
	var rsp: String = Data.COUNTER[sp]
	await M.say(["Hold up. Kettle's handing out strains? Without me?", "I'll have that one. The %s." % Data.SPECIES[rsp].name, "Come on then. First battle of the trip. Loser buys the first round."], "OLI")
	Game.mark_seen(rsp)
	var res: String = await M.start_battle({"kind": "trainer", "rival": true, "name": "OLI", "foes": [Game.mk_mon(rsp, 5)],
		"coins": 100, "sheet": "oli", "bg": "ferry", "lose_line": "Fine. FINE. First round's on me."})
	Game.set_flag("rival1_" + ("win" if res == "win" else "lose"))
	if res == "win":
		await M.say(["I'll get you back in Amsterdam. Watch."], "OLI")
	else:
		await M.say(["Ha! Easy. You're buying.", "Watkins scores around 83-86. Just like that."], "OLI")
	await _heal()
	await M.say(["Let me patch them up.", "Have a look round the boat. The cargo nets at the back are full of stowaway strains.", "Weaken one first, then lob a Tin at it. You've got five.", "Come back to me when you're ready to go ashore."], "KETTLE")
	await o.walk_path([3])
	o.face(1)
	Game.set_flag("intro_done")
	Game.state.heal_map = "ferry"
	Game.state.heal_x = 11
	Game.state.heal_y = 16


func _arrival(W: World) -> void:
	var M = Game.main
	await M.say(["Right. Let's go."], "KETTLE")
	Sfx.stop_music()
	Sfx.play("horn")
	await M.fade_out(0.8)
	await M.caption("Some hours later...")
	Game.set_flag("arrived")
	Game.state.heal_map = "quay"
	Game.state.heal_x = 20
	Game.state.heal_y = 7
	W.load_map("quay", Vector2i(16, 9), 3)
	await M.fade_in(0.8)
	var k = W.npc("kettle")
	if k:
		k.face(0)
	await M.say(["Amsterdam. Smell that?", "...That's the canal, mate.", "We're booked into the hostel up there. Rest whenever you want.", "Strains come out in the park planters over the bridge. Have a look."], "KETTLE")
	Game.save_game()
