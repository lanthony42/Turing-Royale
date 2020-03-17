%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% AI CONTROLLER CLASS %%%%%
class AIControl
    inherit Object
    import Player, Item, WeaponType
    export var all

    % AI neural node
    type neuralNode :
	record
	    t, value : real
	end record

    var aiItem : ^Item
    var aiPlayer, aiTarget : ^Player
    var rTester, aTester : Collider
    var network : array 1 .. NODE_MAX of neuralNode
    var adjMatrix : array 1 .. NODE_MAX of array 1 .. NODE_MAX of real

    var aimPos, tPos, direction : vector
    var movement, action : int
    var roamPossible, attackPossible, stuck : boolean
    var coWeapons, coBullets, coHealth, coReload : real

    forward fcn changeWeapon (c : int) : boolean

    forward proc reload ()
    forward proc roam ()
    forward proc roamTo ()
    forward proc roamAway ()
    forward proc avoid ()
    forward proc attack ()
    forward proc knife ()
    forward proc pickUp ()

    % Constructor
    proc initial (on : boolean, p : ^Player, w, b, h, r : real, file : string)
	uid := -1
	enabled := on
	roamPossible := true
	attackPossible := true
	aiPlayer := p
	aiItem := nil (Item)
	aiTarget := nil (Player)
	collider := Collide.comp ('B', 0, 0, 0, 0, 0)
	collider.v := Vector.sub (aiPlayer -> collider.v, Vector.comp (SCR_WH, SCR_HH))
	collider.w := Vector.add (collider.v, Vector.comp (SCR_WIDTH, SCR_HEIGHT))
	rTester := Collide.comp ('R', 0, 0, 0, 0, 0)
	aTester := Collide.comp ('R', 0, 0, 0, 0, 0)
	direction := Vector.comp (0, 0)

	var aiInput : string
	var aiStream : int
	open : aiStream, file, get
	get : aiStream, aiInput : *
	for i : 1 .. NODE_MAX     % Start Node
	    for j : 1 .. NODE_MAX     % End Node
		exit when eof (aiStream)
		get : aiStream, aiInput
		adjMatrix (i) (j) := strreal (aiInput)
	    end for
	end for
	close : aiStream

	for i : 1 .. IN_MAX
	    network (i).t := INPUT
	end for
	for i : 1 .. OUT_MAX
	    network (i + IN_MAX).t := OUTPUT
	end for
	network (ITEMCTRL).t := PMHALF
	network (SAFETY).t := PLUSMIN

	if enabled then
	    var random : int := Rand.Int (1, 100)
	    if random <= P_SHOTGUN then
		aiPlayer -> weaponTypes (1).t := PISTOL
	    elsif random <= P_RIFLE then
		aiPlayer -> weaponTypes (1).t := SHOTGUN
	    elsif random <= P_LASER then
		aiPlayer -> weaponTypes (1).t := LASER
	    else
		aiPlayer -> weaponTypes (1).t := SNIPER
	    end if

	    aiPlayer -> weaponTypes (1).rarity := COMMON
	    aiPlayer -> weaponTypes (1).clipAmount := clipBase (aiPlayer -> weaponTypes (1).t) * 2
	    aiPlayer -> bulletAmount := 50
	    if changeWeapon (1) then
	    end if

	    aiPlayer -> speed := MAX_SPEED * 0.8
	end if

	coWeapons := w
	coBullets := b
	coHealth := h
	coReload := r
	aimPos := Vector.comp (Rand.Int (0, WIDTH), Rand.Int (0, HEIGHT))
	tPos := Vector.comp (Rand.Int (0, WIDTH), Rand.Int (0, HEIGHT))
	action := 0
	movement := 0

	for i : 1 .. NODE_MAX
	    network (i).value := 0
	end for
	network (BIAS).value := BIAS
	network (THREAT).value := aiPlayer -> danger (coWeapons, coBullets, coHealth, coReload)
    end initial

    % Update player based on AI network
    proc update ()
	enabled := aiPlayer -> enabled
	collider.v := Vector.sub (aiPlayer -> collider.v, Vector.comp (SCR_WH, SCR_HH))
	collider.w := Vector.add (collider.v, Vector.comp (SCR_WIDTH, SCR_HEIGHT))
	rTester.v := aiPlayer -> collider.v
	rTester.w := Vector.add (rTester.v, Vector.make (MAX_SPEED + PLAYER_RAD * 1.5, Vector.dir_points (rTester.v, aimPos) + PI))
	aTester.v := aiPlayer -> collider.v
	if aiTarget ~= nil then
	    aTester.w := Vector.add (aTester.v, Vector.make (SCR_WIDTH, Vector.dir_points (aTester.v, aiTarget -> collider.v) + PI))
	end if
	%Draw.ThickLine (drawX (aTester.v.x), drawY (aTester.v.y), drawX (aTester.w.x), drawY (aTester.w.y), 2, white)

	% Get input nodes
	network (THREAT).value := aiPlayer -> danger (coWeapons, coBullets, coHealth, coReload)
	stuck := Vector.mag (Vector.sub (aiPlayer -> collider.v, aiPlayer -> collider.w)) < ACCELERATION / 2 - 1
	if aiPlayer -> itemCollide then
	    network (ONITEM).value := 1
	else
	    network (ONITEM).value := 0
	end if
	if network (TARGET).value = 0 then
	    aiTarget := nil (Player)
	    network (DANGER).value := 0
	end if
	Vector.approx (aimPos)
	if action ~= ATTACK then
	    aiPlayer -> direction := Vector.dir_points (aiPlayer -> collider.v, tPos) + PI
	end if

	% Get intermediate nodes
	for j : IN_MAX + OUT_MAX + 1 .. NODE_MAX
	    var val, base : real := 0
	    for i : 1 .. NODE_MAX
		if abs (adjMatrix (i) (j)) = BASEW then
		    if network (i).value > 0 then
			base := sign (adjMatrix (i) (j))
		    else
			base := sign (adjMatrix (i) (j) * -1)
		    end if
		elsif adjMatrix (i) (j) ~= 0 then
		    % Multiply input value by weight value
		    val += network (i).value * adjMatrix (i) (j)
		end if
	    end for
	    if network (j).t = PLUSMIN then
		clamp_real (val, -1, 1)
		val := val / 2 + 1
	    end if
	    network (j).value := val * base
	    clamp_real (network (j).value, -1, 1)
	end for

	% Debug
	% var s : string := ""
	% for i : 1 .. NODE_MAX
	%     s += realstr (network (i).value, 0) + " "
	% end for
	% put s, " ", attackPossible, " ", roamPossible

	% Calculate active output nodes
	for j : IN_MAX + 1 .. IN_MAX + OUT_MAX
	    var out : real := 0
	    for i : 1 .. NODE_MAX
		if adjMatrix (i) (j) ~= 0 and (network (i).t = PMHALF or network (i).t = PLUSMIN) then
		    if network (i).value < 0 then
			out := -1
			exit
		    end if
		    clamp_real (network (i).value, 0, 1)
		    out += network (i).value * adjMatrix (i) (j)
		elsif adjMatrix (i) (j) ~= 0 then
		    % Multiply output value by weight value
		    out += network (i).value * adjMatrix (i) (j)
		end if
	    end for
	    network (j).value := out
	    clamp_real (network (j).value, -1, 1)
	end for

	% Determine actions
	if network (RELOAD).value > ACTIVATION then
	    reload
	    action := RELOAD
	    %put "reload"
	elsif network (ATTACK).value > ACTIVATION then
	    aiPlayer -> getWeapon
	    if attackPossible then
		attack
	    else
		knife
	    end if
	    action := ATTACK
	    %put "attack"
	end if

	if stuck then
	    roam
	    %put "random"
	elsif network (RTARGET).value > ACTIVATION then
	    movement := RTARGET
	    if direction.x ~= 0 or direction.y ~= 0 then
		avoid
	    elsif aiTarget ~= nil then
		tPos := aiTarget -> collider.v
		roamTo
		%put "target"
	    end if
	elsif network (RATARGET).value >= 0 and network (RATARGET).value <= ACTIVATION then
	    movement := RTARGET
	    if direction.x ~= 0 or direction.y ~= 0 then
		avoid
	    elsif aiTarget ~= nil then
		tPos := aiTarget -> collider.v
		roamAway
		%put "away"
	    end if
	elsif network (RRAND).value > ACTIVATION then
	    if direction.x ~= 0 or direction.y ~= 0 then
		avoid
	    else
		roam
		%put "random"
	    end if
	elsif network (RITEM).value >= 0 and network (RITEM).value <= ACTIVATION * 0.8 then
	    movement := RTARGET
	    if direction.x ~= 0 or direction.y ~= 0 then
		avoid
	    elsif aiItem ~= nil then
		tPos := aiItem -> collider.v
		roamTo
		%put "item"
	    end if
	elsif network (GITEM).value > ACTIVATION then
	    %put "pickup"
	    pickUp
	end if

	% Reset Values
	direction := Vector.comp (0, 0)
	network (TARGET).value := 0
	network (ITEMSCR).value := 0
	attackPossible := true
	roamPossible := true
    end update

    % Destroy AI
    proc destroy ()
	enabled := false
    end destroy

    % Set target
    proc setTarget (t : ^Player)
	aiTarget := t
	network (TARGET).value := 1
	network (DANGER).value := aiTarget -> danger (coWeapons, coBullets, coHealth, coReload)
    end setTarget

    proc setItem (i : ^Item)
	aiItem := i
	network (ITEMSCR).value := 1
    end setItem

    body fcn changeWeapon (c : int) : boolean
	if (aiPlayer -> weaponTypes (c).t ~= NULL and aiPlayer -> weaponTypes (c).clipAmount > 0) or aiPlayer -> weaponTypes (c).t = KNIFE then
	    aiPlayer -> currentWeapon := c
	    aiPlayer -> getWeapon
	    result true
	end if
	result false
    end changeWeapon

    fcn changeW (c : int) : boolean
	if aiPlayer -> weaponTypes (c).t ~= NULL then
	    aiPlayer -> currentWeapon := c
	    aiPlayer -> getWeapon
	    if aiPlayer -> weaponTypes (c).t ~= KNIFE then
		result aiPlayer -> weaponTypes (c).clipAmount < aiPlayer -> weaponStats.maxClip
	    else
		result true
	    end if
	end if
	result false
    end changeW

    % Possible output nodes
    % Reload all guns
    body proc reload ()
	if ~aiPlayer -> reloading and aiPlayer -> weaponTypes (aiPlayer -> currentWeapon).clipAmount < aiPlayer -> weaponStats.maxClip then
	    aiPlayer -> reloading := true
	elsif ~aiPlayer -> reloading then
	    var change : int := aiPlayer -> currentWeapon + 1
	    loop
		exit when changeW (change mod (WEAPON_MAX + 1))
		change += 1
	    end loop
	end if
    end reload

    % Free roam
    body proc roam ()
	aimPos := Vector.make (1, Vector.dir (aimPos) + Rand.Real () / 8)
	aiPlayer -> speed := MAX_SPEED * 1.1
	aiPlayer -> moved := true
	aiPlayer -> accel := aimPos

	if action ~= ATTACK then
	    aiPlayer -> direction := Vector.dir_points (aiPlayer -> collider.v, aimPos) + PI
	end if
    end roam

    % Roam towards a target
    body proc roamTo ()
	aimPos := tPos
	aiPlayer -> speed := MAX_SPEED * 0.8
	if (aiPlayer -> collider.v.x - tPos.x) ** 2 + (aiPlayer -> collider.v.y - tPos.y) ** 2 > (aiPlayer -> weaponStats.range + PLAYER_RAD * 2) ** 2 then
	    aiPlayer -> moved := true
	    aiPlayer -> accel := Vector.sub (aimPos, aiPlayer -> collider.v)
	end if
    end roamTo

    % Roam away from a target
    body proc roamAway ()
	aimPos := Vector.add (aiPlayer -> collider.v, Vector.sub (aiPlayer -> collider.v, tPos))
	aiPlayer -> speed := MAX_SPEED
	var v : vector := Vector.sub (Vector.normal (aimPos), Vector.normal (tPos))
	aimPos := Vector.add (aimPos, Vector.make (10, Vector.dir (v) + PI))
	aiPlayer -> moved := true
	aiPlayer -> accel := Vector.sub (aimPos, aiPlayer -> collider.v)
    end roamAway

    % Avoid obstacles
    body proc avoid ()
	%put "avoid ", Vector.str (direction)
	aiPlayer -> moved := true
	aiPlayer -> accel := direction
    end avoid

    % Attack target
    body proc attack ()
	aiPlayer -> direction := Vector.dir_points (aiPlayer -> collider.v, aiTarget -> collider.v) + PI
	if aiPlayer -> weaponTypes (aiPlayer -> currentWeapon).clipAmount > 0 and aiPlayer -> weaponTypes (aiPlayer -> currentWeapon).t ~= KNIFE then
	    aiPlayer -> attacking := true
	elsif aiPlayer -> bulletAmount <= 0 then
	    knife
	else
	    var change : int := aiPlayer -> currentWeapon + 1
	    loop
		exit when changeWeapon (change mod (WEAPON_MAX + 1))
		change += 1
	    end loop
	    aiPlayer -> attacking := true
	end if
    end attack

    % Attack target
    body proc knife ()
	aiPlayer -> direction := Vector.dir_points (aiPlayer -> collider.v, aiTarget -> collider.v) + PI
	if changeWeapon (KNIFE) then
	    aiPlayer -> attacking := true
	end if
    end knife

    % Pick up items
    body proc pickUp ()
	if aiPlayer -> bulletAmount + aiPlayer -> onItem -> bulletAmount > BULLETS then
	    aiPlayer -> onItem -> bulletAmount -= BULLETS - aiPlayer -> bulletAmount
	    aiPlayer -> bulletAmount := BULLETS
	else
	    aiPlayer -> bulletAmount += aiPlayer -> onItem -> bulletAmount
	    aiPlayer -> onItem -> bulletAmount := 0
	end if
	var curWeapon : int
	for j : 1 .. WEAPONI_MAX
	    for i : 1 .. WEAPON_MAX
		if aiPlayer -> weaponTypes (i).t = NULL then
		    curWeapon := i
		    exit
		else
		    curWeapon := aiPlayer -> currentWeapon
		end if
	    end for
	    var playerW : wType := aiPlayer -> weaponTypes (curWeapon)
	    if playerW.t ~= KNIFE and WeaponType.rating (aiPlayer -> weaponTypes (curWeapon)) < WeaponType.rating (aiPlayer -> onItem -> weaponTypes (j)) then
		aiPlayer -> weaponTypes (curWeapon) := aiPlayer -> onItem -> weaponTypes (j)
		aiPlayer -> onItem -> weaponTypes (j) := playerW
	    end if
	    aiPlayer -> getWeapon
	end for
    end pickUp
end AIControl
