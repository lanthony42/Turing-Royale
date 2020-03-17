%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% INITIALIZATION %%%%%
module Init
    import File, Vector, Quadtree, Object, Player, AIControl, Item, Projectile, Raycast, Wall, Cover
    export var * ~.all

    var timeText : string
    var startTime, currentTime : int

    % Main objects
    var baseTree : ^Quadtree
    var entities : array 1 .. (PROJ_MAX + 3) * PLAYER_MAX + WALL_MAX + COVER_MAX + ITEM_MAX of ^Object
    var items : array 1 .. ITEM_MAX + PLAYER_MAX of ^Item
    var players : array 1 .. PLAYER_MAX of ^Player
    var playerAI : array 1 .. PLAYER_MAX of ^AIControl
    var walls : array 1 .. WALL_MAX of ^Wall
    var covers : array 1 .. COVER_MAX of ^Cover

    % Score info
    type score :
	record
	    name : string
	    val : int
	end record
    var scores : flexible array 1 .. 0 of score

    % Get scoreboard from file
    proc getScore ()
	var input : string
	var stream : int
	open : stream, "files/Data/Score.data", get
	loop
	    exit when eof (stream)

	    new scores, upper (scores) + 1
	    get : stream, input : *
	    scores (upper (scores)).name := input
	    get : stream, input
	    scores (upper (scores)).val := strint (input)
	end loop
	close : stream
    end getScore

    % Initial colors
    proc initColor ()
	RGB.SetColor (C_BACK, 0, 0, 0.05)
	colorback (C_BACK)

	RGB.SetColor (C_YELLOW, 1, 1, 0.8)
	RGB.SetColor (C_BLUE, 0.8, 0.85, 1)
	RGB.SetColor (C_GREEN, 0.6, 0.9, 0.7)
	RGB.SetColor (C_PURPLE, 0.9, 0.75, 1)
	RGB.SetColor (C_ORANGE, 1, 0.9, 0.8)
	RGB.SetColor (C_RED, 1, 0.8, 0.8)
	RGB.SetColor (C_ORANGER, 1, 0.85, 0.7)
	RGB.SetColor (C_GREENER, 0.35, 0.75, 0.45)

	RGB.SetColor (C_PROJ, 0.95, 0.95, 0)
	RGB.SetColor (C_LASER, 0.8, 0, 0)
	RGB.SetColor (C_LASERI, 0.9, 0, 0)
	RGB.SetColor (C_ITEM, 0.8, 1, 1)
	RGB.SetColor (C_ITEMI, 0, 0.07, 0.1)
	RGB.SetColor (C_UI, 0, 0, 0.065)
	RGB.SetColor (C_GRAY, 0.5, 0.5, 0.5)
	Text.Color (C_YELLOW)
    end initColor

    % Initialize game
    proc initial ()
	new Quadtree, baseTree
	baseTree -> initTree
	var stream, c : int
	var px, py, dx, dy : real
	var input : string

	% Initialize entities
	var entityCount : int := PLAYER_MAX
	playerCount := 0

	% Player initialization
	for i : 1 .. PLAYER_MAX
	    % Initialize AI
	    var file : string
	    if File.Exists ("files/Data/AI Data/Bot " + intstr (i) + ".data") then
		file := "files/Data/AI Data/Bot " + intstr (i) + ".data"
	    else
		file := "files/Data/AI Data/Bot Base.data"
	    end if
	    open : stream, file, get
	    get : stream, input
	    px := strreal (input)
	    get : stream, input
	    py := strreal (input)
	    get : stream, input
	    dx := strreal (input)
	    get : stream, input
	    dy := strreal (input)
	    close : stream

	    % Initialize players
	    new Player, players (i)
	    new AIControl, playerAI (i)
	    if i = player then
		players (i) -> initial (true, playerName, 0, Rand.Int (0, WIDTH), Rand.Int (0, HEIGHT), C_ORANGE)
		playerAI (i) -> initial (false, players (i), px, py, dx, dy, file)
	    else
		players (i) -> initial (true, "BOT " + intstr (i), 0, Rand.Int (0, WIDTH), Rand.Int (0, HEIGHT), C_YELLOW)
		playerAI (i) -> initial (true, players (i), px, py, dx, dy, file)
	    end if
	    players (i) -> uid := i
	    entities (i) := players (i)

	    % Projectile initialization
	    for j : 1 .. PROJ_MAX
		new Projectile, players (i) -> projectiles (j)
		players (i) -> projectiles (j) -> initial (false, Vector.comp (0, 0), 0, 0, 0, 0)
		entityCount += 1
		players (i) -> projectiles (j) -> uid := entityCount
		entities (entityCount) := players (i) -> projectiles (j)
	    end for

	    % Ray initialization
	    new Raycast, players (i) -> raycast
	    players (i) -> raycast -> initial (false, Vector.comp (0, 0), 0, 0, 0, 0, 0, 0)
	    players (i) -> raycast -> uid := PLAYER_MAX * PROJ_MAX + PLAYER_MAX + i
	    entities (PLAYER_MAX * PROJ_MAX + PLAYER_MAX + i) := players (i) -> raycast

	    % Player death item initialization
	    new Item, items (ITEM_MAX + i)
	    items (ITEM_MAX + i) -> initial (false, Vector.comp (0, 0), 0, 0)
	    items (ITEM_MAX + i) -> uid := (PROJ_MAX + 2) * PLAYER_MAX + WALL_MAX + COVER_MAX + ITEM_MAX + i
	    entities ((PROJ_MAX + 2) * PLAYER_MAX + WALL_MAX + COVER_MAX + ITEM_MAX + i) := items (ITEM_MAX + i)
	    players (i) -> itemBox := items (ITEM_MAX + i)
	end for

	% Read obstacle data
	% Wall initialization
	open : stream, "files/Data/Wall.data", get
	for i : 1 .. WALL_MAX
	    exit when eof (stream)
	    get : stream, input
	    px := strint (input)
	    get : stream, input
	    py := strint (input)
	    get : stream, input
	    dx := strint (input)
	    get : stream, input
	    dy := strint (input)
	    get : stream, input
	    c := colorTypes (strint (input))
	    get : stream, input

	    new Wall, walls (i)
	    walls (i) -> initial (true, Vector.comp (px, py), Vector.comp (dx, dy), c, input)
	    walls (i) -> uid := (PROJ_MAX + 2) * PLAYER_MAX + i
	    entities ((PROJ_MAX + 2) * PLAYER_MAX + i) := walls (i)
	    baseTree -> insert (walls (i))
	end for
	close : stream

	% Cover initialization
	open : stream, "files/Data/Cover.data", get
	for i : 1 .. COVER_MAX
	    exit when eof (stream)
	    get : stream, input
	    px := strint (input)
	    get : stream, input
	    py := strint (input)
	    get : stream, input
	    dx := strint (input)
	    get : stream, input
	    c := colorTypes (strint (input))

	    new Cover, covers (i)
	    covers (i) -> initial (true, Vector.comp (px, py), c, dx)
	    covers (i) -> uid := (PROJ_MAX + 2) * PLAYER_MAX + WALL_MAX + i
	    entities ((PROJ_MAX + 2) * PLAYER_MAX + WALL_MAX + i) := covers (i)
	end for
	close : stream

	% Item initialization
	open : stream, "files/Data/Item.data", get
	for i : 1 .. ITEM_MAX
	    exit when eof (stream)
	    get : stream, input
	    px := strint (input)
	    get : stream, input
	    py := strint (input)
	    get : stream, input
	    c := colorTypes (strint (input))

	    new Item, items (i)
	    items (i) -> initial (true, Vector.comp (px - ITEM_W div 2, py - ITEM_H div 2), 1, c)
	    items (i) -> uid := (PROJ_MAX + 2) * PLAYER_MAX + WALL_MAX + COVER_MAX + i
	    entities ((PROJ_MAX + 2) * PLAYER_MAX + WALL_MAX + COVER_MAX + i) := items (i)
	    items (i) -> random
	end for
	close : stream
    end initial
end Init

%%%%% UPDATE HANDLING %%%%%
module Update
    import Vector, Collide, Object, Quadtree, Player, Item, Projectile, Raycast, Wall, Cover
    export var * ~.all

    % Menu Draw
    var state : int := M_PROJ
    var gunX : array 1 .. * of int := init (146, 116, 236, 266)
    var gunY : array 1 .. * of int := init (110, 150, 250, 210)
    var projPos : vector := Vector.comp (155, 150)

    proc menuDraw ()
	if state = M_PROJ then
	    if projPos.y > SCR_HEIGHT then
		projPos := Vector.comp (155, 150)
		state := Rand.Int (1, 2)
	    else
		projPos := Vector.add (projPos, Vector.comp (24, 20))
	    end if
	elsif state = M_LASER then
	    Draw.ThickLine (round (projPos.x), round (projPos.y), 707, 610, 35, C_LASER)
	    Draw.ThickLine (round (projPos.x), round (projPos.y), 707, 610, 20, C_LASERI)
	    if Rand.Real () < 0.9 then
		state := M_LASER
	    else
		state := M_STOP
	    end if
	else
	    state := Rand.Int (2, 20)
	end if

	Draw.FillOval (round (projPos.x), round (projPos.y), 8, 8, C_PROJ)
	Draw.FillPolygon (gunX, gunY, 4, brown)
	Draw.FillOval (650, 50, 150, 150, C_GREEN)
	Draw.FillOval (650, 50, 140, 140, C_BACK)
	Draw.FillOval (450, 650, 110, 110, C_BLUE)
	Draw.FillOval (450, 650, 100, 100, C_BACK)
	Draw.FillBox (-1, 300, 45, SCR_HEIGHT, C_PURPLE)
	Draw.FillBox (-1, 310, 35, SCR_HEIGHT, C_BACK)

	Draw.FillOval (220, 120, 25, 25, C_ORANGE)
	Draw.FillOval (220, 120, 15, 15, C_BACK)
	Draw.FillOval (170, 220, 25, 25, C_ORANGE)
	Draw.FillOval (170, 220, 15, 15, C_BACK)
	Draw.FillOval (150, 150, 80, 80, C_ORANGE)
	Draw.FillOval (150, 150, 70, 70, C_BACK)

	Draw.Text ("TURING ROYALE", SCR_WH - 212, UI_INV_Y - 175, Font.New ("sans serif:38:bold"), C_YELLOW)
	Draw.Text ("Press 'P' to continue", SCR_WH - 105, UI_INV_Y - 250, Font.New ("sans serif:16"), C_YELLOW)
	Draw.Text ("Press 'T' to view instructions", SCR_WH - 140, UI_INV_Y - 300, Font.New ("sans serif:16"), C_YELLOW)
	Draw.Text ("Press 'S' to show scoreboard", SCR_WH - 145, UI_INV_Y - 350, Font.New ("sans serif:16"), C_YELLOW)
    end menuDraw

    % Tutorial Draw
    proc tutDraw ()
	Draw.Text ("WASD keys to move, 'R' to reload.", UI_HEALTH_Y * 2, SCR_HEIGHT - 50, Font.New ("sans serif:16"), C_YELLOW)
	Draw.Text ("'Q' or 'E' keys to change weapons, numbers 1 - 5 to select weapon.", UI_HEALTH_Y * 2, SCR_HEIGHT - 150, Font.New ("sans serif:16"), C_YELLOW)
	Draw.Text ("Mouse or spacebar to shoot.", UI_HEALTH_Y * 2, SCR_HEIGHT - 250, Font.New ("sans serif:16"), C_YELLOW)
	Draw.Text ("'F' key to open item boxes, 'I' or tab key to open inventory.", UI_HEALTH_Y * 2, SCR_HEIGHT - 350, Font.New ("sans serif:16"), C_YELLOW)
	Draw.Text ("Try to be the last man standing! Pay attention to the rarity of the weapons.", UI_HEALTH_Y * 2, SCR_HEIGHT - 450, Font.New ("sans serif:16"), C_YELLOW)
    end tutDraw

    % Print out scoreboard
    proc scoreDraw ()
	put "High Scores:\n"
	for i : 1 .. upper (scores)
	    put "#", intstr (i, 2), "" : 5, scores (i).name : 80, intstr (scores (i).val, 3)
	end for
    end scoreDraw

    % Update score
    proc updateScore ()
	var stream : int
	var placed : boolean := false
	Dir.Delete ("files/Data/Score.data")
	open : stream, "files/Data/Score.data", put
	for i : 1 .. upper (scores)
	    if players (player) -> fitness () > scores (i).val and ~placed then
		put : stream, players (player) -> name
		put : stream, round (players (player) -> fitness ())
		placed := true
	    end if
	    put : stream, scores (i).name
	    put : stream, scores (i).val
	end for
	close : stream

	new scores, 0
	getScore
    end updateScore

    % Update values
    proc update ()
	var quad : ^Quadtree
	new Quadtree, quad
	quad -> initTree
	var itemTree : ^Quadtree
	new Quadtree, itemTree
	itemTree -> initTree

	currentTime := (ticks - startTime) div 1000
	timeText := frealstr ((currentTime div 60) + (currentTime mod 60) / 100, 0, 2)
	timeText := timeText (1 .. index (timeText, ".") - 1) + ":" + timeText (index (timeText, ".") + 1 .. length (timeText))

	% Main value updates for entities
	for i : 1 .. PLAYER_MAX
	    if playerAI (i) -> enabled then
		playerAI (i) -> update
	    end if
	    if players (i) -> enabled then
		players (i) -> update
		quad -> insert (players (i))
	    end if
	    for j : 1 .. PROJ_MAX
		if players (i) -> projectiles (j) -> enabled then
		    players (i) -> projectiles (j) -> update
		end if
	    end for
	end for
	for i : 1 .. COVER_MAX
	    if covers (i) -> enabled then
		quad -> insert (covers (i))
	    end if
	end for
	for i : 1 .. ITEM_MAX + PLAYER_MAX
	    if items (i) -> enabled then
		items (i) -> update
		itemTree -> insert (items (i))
	    end if
	end for

	% Collision updates
	var collisionCount : int := 0 % Debug
	% Players collision
	for i : 1 .. PLAYER_MAX
	    if players (i) -> enabled then
		var entList : string := quad -> search (players (i)) + baseTree -> search (players (i))
		loop
		    exit when length (entList) < 3
		    if playerCollision (players (i) -> collider, entities (strint (entList (1 .. 3))) -> collider) then

		    end if
		    entList := entList (4 .. *)
		    collisionCount += 1
		end loop

		entList := itemTree -> search (players (i))
		loop
		    exit when length (entList) < 3
		    if playerCollision (players (i) -> collider, entities (strint (entList (1 .. 3))) -> collider) then
			players (i) -> onItem := entities (strint (entList (1 .. 3)))
			players (i) -> itemCollide := true
			exit
		    else
			players (i) -> itemCollide := false
		    end if
		    entList := entList (4 .. *)
		    collisionCount += 1
		end loop

		if playerAI (i) -> enabled then
		    entList := quad -> search (playerAI (i)) + itemTree -> search (playerAI (i)) + baseTree -> search (playerAI (i))
		    var other, pPossible, iPossible : ^Object := nil (Object)
		    var pDist, iDist : real := SCR_HEIGHT ** 2
		    loop
			exit when length (entList) < 3
			other := entities (strint (entList (1 .. 3)))
			if ~objectclass (other) >= Cover then
			    if objectclass (other) >= Player and other -> uid ~= i then
				var d : real := (players (i) -> collider.v.x - other -> collider.v.x) ** 2 + (players (i) -> collider.v.y - other -> collider.v.y) ** 2
				if pDist > d then
				    pDist := d
				    pPossible := other
				end if
			    elsif objectclass (other) >= Item then
				var d : real := (players (i) -> collider.v.x - other -> collider.v.x) ** 2 + (players (i) -> collider.v.y - other -> collider.v.y) ** 2
				if iDist > d then
				    iDist := d
				    iPossible := other
				end if
			    else % For wall
				var roam : Collider := playerAI (i) -> rTester
				if playerAI (i) -> roamPossible and playerAICollision (roam, other -> collider) then
				    playerAI (i) -> roamPossible := false
				    var dirPos : array 1 .. 4 of boolean
				    for j : 1 .. 4
					roam := Collide.make ('R', roam.v, Vector.add (roam.v, Vector.make (MAX_SPEED * 2 + PLAYER_RAD, Vector.dir (DIRECTIONS (j)))), 0)
					dirPos (j) := playerAICollision (roam, other -> collider)
				    end for
				    if ~dirPos (2) and dirPos (4) then
					playerAI (i) -> direction := Vector.add (DIRECTIONS (3), playerAI (i) -> direction)
				    elsif dirPos (2) and ~dirPos (4) then
					playerAI (i) -> direction := Vector.add (DIRECTIONS (3), playerAI (i) -> direction)
				    end if
				    if ~dirPos (1) and dirPos (3) then
					playerAI (i) -> direction := Vector.add (DIRECTIONS (2), playerAI (i) -> direction)
				    elsif dirPos (1) and ~dirPos (3) then
					playerAI (i) -> direction := Vector.add (DIRECTIONS (4), playerAI (i) -> direction)
				    end if
				end if
				if playerAI (i) -> attackPossible and playerAICollision (playerAI (i) -> aTester, other -> collider) then
				    playerAI (i) -> attackPossible := false
				end if
			    end if
			    collisionCount += 1
			end if
			entList := entList (4 .. *)
		    end loop

		    if pPossible ~= nil (Object) then
			playerAI (i) -> setTarget (pPossible)
		    end if
		    if iPossible ~= nil (Object) then
			playerAI (i) -> setItem (iPossible)
		    end if
		end if
	    end if
	end for
	% Player post collision update
	for i : 1 .. PLAYER_MAX
	    if players (i) -> enabled then
		players (i) -> postUpdate (currentTime)
	    end if
	end for
	% Projectiles collision
	for i : 1 .. PROJ_MAX * PLAYER_MAX
	    var proj : ^Projectile := entities (i + PLAYER_MAX)
	    if proj -> enabled then
		var entList : string := quad -> search (proj) + baseTree -> search (proj)
		loop
		    exit when length (entList) < 3
		    var other : ^Object := entities (strint (entList (1 .. 3)))
		    if projCollision (proj -> collider, other -> collider) then
			if objectclass (other) >= Player then
			    Player (other).health -= proj -> damage
			    Player (other).velocity := Vector.add (Player (other).velocity, Vector.make (proj -> knockback, proj -> direction))
			elsif objectclass (other) >= Cover then
			    Cover (other).health -= proj -> damage
			end if
			proj -> destroy
		    end if
		    entList := entList (4 .. *)
		    collisionCount += 1
		end loop
	    end if
	end for
	% Raycast collision
	for i : 1 .. PLAYER_MAX
	    var ray : ^Raycast := entities (i + (PROJ_MAX + 1) * PLAYER_MAX)
	    if ray -> enabled then
		var entList : string := quad -> search (ray) + baseTree -> search (ray)
		var possible : ^Object := nil (Object)
		var w : vector := ray -> collider.w
		loop
		    exit when length (entList) < 3
		    var other : ^Object := entities (strint (entList (1 .. 3)))
		    if rayCollision (ray -> collider, other -> collider, w) then
			possible := other
		    end if
		    entList := entList (4 .. *)
		    collisionCount += 1
		end loop
		if possible ~= nil then
		    if objectclass (possible) >= Player then
			Player (possible).health -= ray -> damage
			Player (possible).velocity := Vector.add (Player (possible).velocity, Vector.make (ray -> knockback, ray -> direction))
		    elsif objectclass (possible) >= Cover then
			Cover (possible).health -= ray -> damage
			if ray -> weaponType = KNIFE then
			    players (i) -> bulletAmount += 1
			end if
			clamp (players (i) -> bulletAmount, 0, BULLETS)
		    end if
		    ray -> collider.w := w
		end if
	    end if
	end for
	%put collisionCount % Debug
	% Late update cover
	for i : 1 .. COVER_MAX
	    if covers (i) -> enabled then
		covers (i) -> update
	    end if
	end for

	%quad -> draw % Debug
	% Clear memory of quadtrees for recreation
	quad -> delete
	free Quadtree, quad
	itemTree -> delete
	free Quadtree, itemTree
    end update

    % Draw entities
    proc draw ()
	for i : 1 .. COVER_MAX
	    if covers (i) -> enabled then
		covers (i) -> draw
	    end if
	end for
	for i : 1 .. ITEM_MAX + PLAYER_MAX
	    if items (i) -> enabled then
		items (i) -> draw
	    end if
	end for
	for i : 1 .. PLAYER_MAX
	    if players (i) -> enabled then
		for j : 1 .. PROJ_MAX
		    if players (i) -> projectiles (j) -> enabled then
			players (i) -> projectiles (j) -> draw
		    end if
		end for
		if players (i) -> raycast -> enabled then
		    players (i) -> raycast -> draw
		end if
		players (i) -> draw
	    end if
	end for
	for i : 1 .. WALL_MAX
	    if walls (i) -> enabled then
		walls (i) -> draw
	    end if
	end for
    end draw
end Update

%%%%% UI UPDATING %%%%%
module UI
    import Player, Vector, Collide
    export var * ~.all

    var buttons : array 0 .. 7 of Collider
    var showInv, showItem : boolean
    var healthWidth, buttonOver : int

    % Initialize values for UI
    proc initUI ()
	buttons (0) := Collide.make ('B', Vector.comp (UI_INV_X + UI_INV_W, UI_HEALTH_Y + UI_INV_H * 4), Vector.comp (UI_INV_WX, UI_HEALTH_Y + UI_INV_H * 5), 0)
	for i : 1 .. WEAPON_MAX
	    buttons (i) := Collide.make ('B', Vector.comp (UI_INV_X, UI_HEALTH_Y + UI_INV_H * (4 - i)), Vector.comp (UI_INV_WX, UI_HEALTH_Y + UI_INV_H * (5 - i)), 0)
	end for
	for i : 1 .. WEAPONI_MAX
	    buttons (i + WEAPON_MAX) := Collide.make ('B', Vector.comp (SCR_WIDTH - UI_INV_WX, UI_HEALTH_Y + UI_INV_H * i), Vector.comp (SCR_WIDTH - UI_INV_X, UI_HEALTH_Y + UI_INV_H * (i + 1)), 0)
	end for
	buttons (upper (buttons)) := Collide.make ('B', Vector.comp (SCR_WIDTH - UI_INV_WX, UI_HEALTH_Y), Vector.comp (SCR_WIDTH - UI_INV_X - UI_INV_W, UI_HEALTH_Y + UI_INV_H), 0)

	showInv := false
	showItem := false
	healthWidth := UI_HEALTH_W
    end initUI

    % Update camera location to current player's location
    proc updateCam ()
	camX := round (players (player) -> collider.v.x - SCR_WH)
	camY := round (players (player) -> collider.v.y - SCR_HH)
	clamp (camX, 0, WIDTH - SCR_WIDTH)
	clamp (camY, 0, HEIGHT - SCR_HEIGHT)
    end updateCam

    % Draws and updates UI
    proc updateUI ()
	clamp (players (player) -> health, 0, HEALTH)
	healthWidth := round (players (player) -> health / HEALTH * UI_HEALTH_W)

	% Time
	Draw.Text (timeText, UI_HEALTH_Y, UI_INV_Y - 18, Font.New ("sans serif:18:bold"), C_YELLOW)
	Draw.Text (intstr (round (players (player) -> fitness ()), 3), SCR_WIDTH - 50, UI_INV_Y - 18, Font.New ("sans serif:18:bold"), C_YELLOW)
	Draw.Text ("Players Left: " + intstr (playerCount, 2), SCR_WH - 70, UI_INV_Y - 18, Font.New ("sans serif:16:bold"), C_YELLOW)

	% Health bar
	drawfillbox (UI_HEALTH_X - BORDER_W, UI_HEALTH_Y - BORDER_W, UI_HEALTH_X + UI_HEALTH_W + BORDER_W, UI_HEALTH_Y + UI_HEALTH_H + BORDER_W, C_UI)
	drawfillbox (UI_HEALTH_X, UI_HEALTH_Y, UI_HEALTH_X + UI_HEALTH_W, UI_HEALTH_Y + UI_HEALTH_H, C_RED)
	drawfillbox (UI_HEALTH_X, UI_HEALTH_Y, UI_HEALTH_X + healthWidth, UI_HEALTH_Y + UI_HEALTH_H, C_LASERI)
	Draw.Text (intstr (players (player) -> health, 3) + "/100", UI_HEALTH_X + 2, UI_HEALTH_Y + 4, Font.New ("sans serif:14"), C_UI)

	% Name bar
	Draw.Text (players (player) -> name, UI_HEALTH_X, UI_NAMEBAR_Y, Font.New ("sans serif:16:bold"), C_YELLOW)
	Draw.Text (intstr (players (player) -> weaponTypes (players (player) -> currentWeapon).clipAmount, 3) + " /" + intstr (players (player) -> bulletAmount, 4), UI_HEALTH_X + UI_BULLET_W,
	    UI_NAMEBAR_Y, Font.New ("sans serif:15:bold"), C_YELLOW)

	% Inventory
	if showInv or (showItem and players (player) -> itemCollide) then
	    var curWeapon : int := players (player) -> currentWeapon

	    for i : 0 .. WEAPON_MAX
		if players (player) -> weaponTypes (i).rarity = NULL then
		    drawfillbox (round (buttons (i).w.x - 3), round (buttons (i).v.y), round (buttons (i).w.x), round (buttons (i).w.y), C_UI)
		elsif players (player) -> weaponTypes (i).rarity = COMMON then
		    drawfillbox (round (buttons (i).w.x - 3), round (buttons (i).v.y), round (buttons (i).w.x), round (buttons (i).w.y), gray)
		elsif players (player) -> weaponTypes (i).rarity = RARE then
		    drawfillbox (round (buttons (i).w.x - 3), round (buttons (i).v.y), round (buttons (i).w.x), round (buttons (i).w.y), C_ORANGER)
		elsif players (player) -> weaponTypes (i).rarity = EPIC then
		    drawfillbox (round (buttons (i).w.x - 3), round (buttons (i).v.y), round (buttons (i).w.x), round (buttons (i).w.y), C_PURPLE)
		end if

		if players (player) -> weaponTypes (i).t = NULL then
		    Draw.Text ("N/A", round (buttons (i).v.x) + 112, round (buttons (i).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> weaponTypes (i).t = PISTOL then
		    Draw.Text ("Pistol", round (buttons (i).v.x) + 100, round (buttons (i).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> weaponTypes (i).t = SHOTGUN then
		    Draw.Text ("Shotgun", round (buttons (i).v.x) + 87, round (buttons (i).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> weaponTypes (i).t = RIFLE then
		    Draw.Text ("Rifle", round (buttons (i).v.x) + 108, round (buttons (i).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> weaponTypes (i).t = LASER then
		    Draw.Text ("Laser", round (buttons (i).v.x) + 100, round (buttons (i).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> weaponTypes (i).t = SNIPER then
		    Draw.Text ("Sniper", round (buttons (i).v.x) + 97, round (buttons (i).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		end if

		drawbox (round (buttons (i).v.x), round (buttons (i).v.y), round (buttons (i).w.x), round (buttons (i).w.y), C_GRAY)
		Draw.Text (intstr (6 - i), UI_INV_X + 4, UI_HEALTH_Y + UI_INV_H div 2 + UI_INV_H * (i - 1) - 3, defFontID, C_YELLOW)
	    end for
	    if buttonOver ~= NULL and buttonOver < 5 and players (player) -> weaponTypes (buttonOver).t ~= NULL then
		drawbox (round (buttons (buttonOver).v.x), round (buttons (buttonOver).v.y), round (buttons (buttonOver).w.x), round (buttons (buttonOver).w.y), white)
	    end if

	    drawbox (round (buttons (curWeapon).v.x), round (buttons (curWeapon).v.y), round (buttons (curWeapon).w.x), round (buttons (curWeapon).w.y), C_YELLOW)
	    Draw.Text ("1", UI_INV_X + UI_INV_W + 4, UI_HEALTH_Y + UI_INV_H div 2 + UI_INV_H * 4 - 3, defFontID, C_YELLOW)
	    Draw.Text ("Knife", round (buttons (0).v.x) + 26, round (buttons (0).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
	end if

	% Item Inventory
	if showItem and players (player) -> itemCollide then
	    for i : 1 .. WEAPONI_MAX
		if players (player) -> onItem -> weaponTypes (i).rarity = NULL then
		    drawfillbox (round (buttons (i + WEAPON_MAX).v.x), round (buttons (i + WEAPON_MAX).v.y), round (buttons (i + WEAPON_MAX).v.x + 3), round (buttons (i + WEAPON_MAX).w.y), C_UI)
		elsif players (player) -> onItem -> weaponTypes (i).rarity = COMMON then
		    drawfillbox (round (buttons (i + WEAPON_MAX).v.x), round (buttons (i + WEAPON_MAX).v.y), round (buttons (i + WEAPON_MAX).v.x + 3), round (buttons (i + WEAPON_MAX).w.y), gray)
		elsif players (player) -> onItem -> weaponTypes (i).rarity = RARE then
		    drawfillbox (round (buttons (i + WEAPON_MAX).v.x), round (buttons (i + WEAPON_MAX).v.y), round (buttons (i + WEAPON_MAX).v.x + 3), round (buttons (i + WEAPON_MAX).w.y),
			C_ORANGER)
		elsif players (player) -> onItem -> weaponTypes (i).rarity = EPIC then
		    drawfillbox (round (buttons (i + WEAPON_MAX).v.x), round (buttons (i + WEAPON_MAX).v.y), round (buttons (i + WEAPON_MAX).v.x + 3), round (buttons (i + WEAPON_MAX).w.y),
			C_PURPLE)
		end if

		if players (player) -> onItem -> weaponTypes (i).t = NULL then
		    Draw.Text ("N/A", round (buttons (i + WEAPON_MAX).v.x) + 10, round (buttons (i + WEAPON_MAX).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> onItem -> weaponTypes (i).t = PISTOL then
		    Draw.Text ("Pistol", round (buttons (i + WEAPON_MAX).v.x) + 10, round (buttons (i + WEAPON_MAX).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> onItem -> weaponTypes (i).t = SHOTGUN then
		    Draw.Text ("Shotgun", round (buttons (i + WEAPON_MAX).v.x) + 10, round (buttons (i + WEAPON_MAX).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> onItem -> weaponTypes (i).t = RIFLE then
		    Draw.Text ("Rifle", round (buttons (i + WEAPON_MAX).v.x) + 10, round (buttons (i + WEAPON_MAX).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> onItem -> weaponTypes (i).t = LASER then
		    Draw.Text ("Laser", round (buttons (i + WEAPON_MAX).v.x) + 10, round (buttons (i + WEAPON_MAX).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		elsif players (player) -> onItem -> weaponTypes (i).t = SNIPER then
		    Draw.Text ("Sniper", round (buttons (i + WEAPON_MAX).v.x) + 10, round (buttons (i + WEAPON_MAX).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
		end if

		drawbox (round (buttons (i + WEAPON_MAX).v.x), round (buttons (i + WEAPON_MAX).v.y), round (buttons (i + WEAPON_MAX).w.x), round (buttons (i + WEAPON_MAX).w.y), C_GRAY)
	    end for
	    if players (player) -> onItem -> bulletAmount ~= 0 then
		drawbox (round (buttons (upper (buttons)).v.x), round (buttons (upper (buttons)).v.y), round (buttons (upper (buttons)).w.x), round (buttons (upper (buttons)).w.y), C_GRAY)
		Draw.Text ("Bullets", round (buttons (upper (buttons)).v.x) + 12, round (buttons (upper (buttons)).v.y) + 6, Font.New ("sans serif:10"), C_YELLOW)
	    end if

	    if buttonOver ~= NULL and ((buttonOver = WEAPON_MAX + 1 and players (player) -> onItem -> weaponTypes (1).t ~= NULL) or (buttonOver = WEAPON_MAX + 2 and players (player) -> onItem ->
		    weaponTypes (2).t ~= NULL) or (players (player) -> onItem -> bulletAmount ~= 0 and buttonOver = upper (buttons))) then
		drawbox (round (buttons (buttonOver).v.x), round (buttons (buttonOver).v.y), round (buttons (buttonOver).w.x), round (buttons (buttonOver).w.y), white)
	    end if
	else
	    showItem := false
	end if

	% Hits / Info
	if players (player) -> reloading and players (player) -> t ~= KNIFE then
	    drawfillbox (UI_HELPER_X, UI_HELPER_H - BORDER_W - 42, UI_HELPER_W, UI_HELPER_H - 20, C_UI)
	    Draw.Text ("Reloading", UI_HELPER_X + BORDER_W, UI_HELPER_H - 40, Font.New ("sans serif:14:bold"), C_YELLOW)
	elsif ~showItem and players (player) -> itemCollide then
	    drawfillbox (UI_HELPER_X - 25, UI_HELPER_H - BORDER_W - 42, UI_HELPER_W + 35, UI_HELPER_H - 20, C_UI)
	    Draw.Text ("Press 'F' To Use", UI_HELPER_X + BORDER_W - 25, UI_HELPER_H - 40, Font.New ("sans serif:14:bold"), C_YELLOW)
	end if

	if ~players (player) -> enabled then
	    Draw.Text ("YOU GOT REKT!", SCR_WH - 200, UI_INV_Y - 175, Font.New ("sans serif:38:bold"), C_YELLOW)
	    Draw.Text ("You were #" + intstr (players (player) -> place, 2), SCR_WH - 80, UI_INV_Y - 230, Font.New ("sans serif:20"), C_YELLOW)
	    Draw.Text ("Press enter to continue", SCR_WH - 105, UI_INV_Y - 270, Font.New ("sans serif:16"), C_YELLOW)
	elsif stage = END then
	    Draw.Text ("EPIC VICTORY ROYALE", SCR_WH - 290, UI_INV_Y - 175, Font.New ("sans serif:38:bold"), C_YELLOW)
	    Draw.Text ("You are # 1", SCR_WH - 75, UI_INV_Y - 230, Font.New ("sans serif:20"), C_YELLOW)
	    Draw.Text ("Press enter to continue", SCR_WH - 105, UI_INV_Y - 270, Font.New ("sans serif:16"), C_YELLOW)
	end if
    end updateUI

    proc getName ()
	loop
	    exit when playerName ~= ""

	    View.Set ("nooffscreenonly,echo")
	    put "Enter name:"
	    get playerName : *
	    View.Set ("offscreenonly,noecho")
	    cls
	end loop
    end getName
end UI
