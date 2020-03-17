%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% BASE PLAYER CLASS %%%%%
class Player
    inherit Object
    import WeaponType, Projectile, Raycast, Item
    export var all

    var name : string
    var velocity, accel, weaponPos : vector

    var moved, attacking, reloading, itemCollide, knife : boolean
    var health, bulletAmount, destroys, timer, reloadTimer, colorType, place : int
    var direction, timeSurvived, maxSpeed, speed : real

    var currentWeapon, t : int
    var weaponStats : wStats
    var weaponTypes : array 0 .. WEAPON_MAX of wType
    var projectiles : array 1 .. PROJ_MAX of ^Projectile
    var raycast : ^Raycast
    var itemBox, onItem : ^Item

    forward proc move (d : int)
    forward proc stop ()

    forward proc getWeapon ()
    forward proc attack ()
    forward proc laser ()
    forward proc reload ()
    forward proc destroy ()
    forward fcn getProjectile () : ^Projectile

    % Constructor
    proc initial (on : boolean, n : string, d, x, y : real, c : int)
	enabled := on
	name := n
	direction := d
	colorType := c
	collider := Collide.make ('M', Vector.comp (x, y), Vector.comp (x, y), PLAYER_RAD)
	velocity := Vector.comp (0, 0)
	accel := Vector.comp (0, 0)
	weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction))

	health := HEALTH
	speed := MAX_SPEED
	bulletAmount := 0
	destroys := 0
	timeSurvived := 0
	maxSpeed := 0
	timer := 0
	place := 0

	% Weapon initializations
	currentWeapon := 0
	reloadTimer := 0
	weaponTypes (0) := WeaponType.knife ()
	% weaponTypes (1) := WeaponType.tSh ()  % Tests
	% weaponTypes (2) := WeaponType.tR ()  % Tests
	% weaponTypes (3) := WeaponType.tL () % Tests
	% weaponTypes (4) := WeaponType.tSn () % Tests
	for i : 1 .. WEAPON_MAX
	    weaponTypes (i) := WeaponType.null ()
	end for
	getWeapon

	playerCount += 1
	itemCollide := false
	attacking := false
	reloading := false
	moved := false
	knife := false
    end initial

    % Update values
    proc update ()
	% Main movement handling
	if moved then
	    maxSpeed := speed * weaponStats.mvmtSpeed
	    accel := Vector.make (ACCELERATION, Vector.dir (accel))
	    Vector.approx (accel)
	    velocity := Vector.add (velocity, accel)
	    Vector.clamp_mag (velocity, 0, maxSpeed)
	end if
	stop

	% Attacking
	if timer > weaponStats.delayAmount * 1000 and attacking and weaponTypes (currentWeapon).clipAmount - weaponStats.bulletLost >= 0 then
	    attack
	    reloading := false
	    reloadTimer := 0
	    timer := 0
	elsif t = LASER and attacking and weaponTypes (currentWeapon).clipAmount - weaponStats.bulletLost >= 0 then
	    laser
	    timer += BASE_DELAY
	    attacking := false
	    knife := false
	else
	    timer += BASE_DELAY
	    attacking := false
	    knife := false
	end if

	% Reloading
	if weaponTypes (currentWeapon).clipAmount >= weaponStats.maxClip or bulletAmount < weaponStats.bulletLost then
	    reloading := false
	elsif weaponTypes (currentWeapon).clipAmount <= 0 then
	    reloading := true
	end if
	if reloadTimer > weaponStats.reloadDelay * 1000 and weaponTypes (currentWeapon).clipAmount < weaponStats.maxClip then
	    reload ()
	    reloading := false
	    reloadTimer := 0
	elsif reloading then
	    reloadTimer += BASE_DELAY
	end if

	% Update Weapon Rays
	if raycast -> enabled then
	    velocity := Vector.add (velocity, Vector.make (weaponStats.recoil, direction + PI))
	end if

	% Update values
	collider.w := collider.v
	collider.v := Vector.add (collider.w, velocity)
	% Keep player in bounds
	Vector.clamp_comp (collider.v, PLAYER_RAD, WIDTH - PLAYER_RAD, PLAYER_RAD, HEIGHT - PLAYER_RAD)

	% Reset values
	accel := Vector.comp (0, 0)
	moved := false
    end update

    % Updates after collision testing
    proc postUpdate (ct : int)
	clamp (health, 0, HEALTH)
	clamp (bulletAmount, 0, BULLETS)
	timeSurvived := ct
	place := playerCount + 1
	if health <= 0 then
	    destroy
	end if

	if raycast -> enabled then
	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction))
	    raycast -> update (t, weaponPos, direction)
	end if
    end postUpdate

    % Render
    proc draw ()
	% Draw weapon
	if reloading then
	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W, direction + PI / 10))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	elsif t ~= KNIFE then
	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction + PI / 5))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	end if
	weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction))

	if t = KNIFE then
	    var endPos : vector := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 3, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), RAY_W * 2, gray)
	    endPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), RAY_W * 2, brown)

	    if knife then
		weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD - 2, direction - PI / 12))
		endPos := Vector.add (weaponPos, Vector.make (5, direction))
		Draw.FillOval (drawX (endPos.x), drawY (endPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
		Draw.FillOval (drawX (endPos.x), drawY (endPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    else
		weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD - 2, direction - PI / 12))
		Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
		Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    end if

	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction + PI / 4))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction))
	elsif t = PISTOL then
	    var endPos : vector := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 4, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 6, brown)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), 5, 5, brown)

	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + 1, direction - PI / 10))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    weaponPos := endPos
	elsif t = SHOTGUN then
	    var startPos : vector := Vector.add (weaponPos, Vector.make (2, direction + PI / 2))
	    var endPos : vector := Vector.add (startPos, Vector.make (BORDER_W * 4, direction))
	    Draw.ThickLine (drawX (startPos.x), drawY (startPos.y), drawX (endPos.x), drawY (endPos.y), 4, blue)
	    startPos := Vector.add (weaponPos, Vector.make (2, direction - PI / 2))
	    endPos := Vector.add (startPos, Vector.make (BORDER_W * 4, direction))
	    Draw.ThickLine (drawX (startPos.x), drawY (startPos.y), drawX (endPos.x), drawY (endPos.y), 4, blue)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), 6, 6, blue)

	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction - PI / 10))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction))
	elsif t = RIFLE then
	    var endPos : vector := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 6, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 4, green)
	    endPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 3, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 8, green)
	    endPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 3, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 2, black)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), 5, 5, green)

	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction - PI / 11))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    weaponPos := endPos
	elsif t = LASER then
	    var endPos : vector := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 4, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 4, C_ITEMI)
	    endPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 3, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 8, red)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), 6, 6, red)

	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction - PI / 10))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    weaponPos := endPos
	elsif t = SNIPER then
	    var endPos : vector := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 9, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 3, purple)
	    Draw.FillOval (drawX (endPos.x), drawY (endPos.y), 2, 2, purple)
	    endPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 5, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 8, purple)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), 6, 6, purple)
	    endPos := Vector.add (collider.v, Vector.make (PLAYER_RAD + BORDER_W * 3, direction))
	    Draw.ThickLine (drawX (weaponPos.x), drawY (weaponPos.y), drawX (endPos.x), drawY (endPos.y), 5, C_ITEMI)

	    weaponPos := Vector.add (collider.v, Vector.make (PLAYER_RAD, direction - PI / 10))
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD, WEAPON_RAD, colorType)
	    Draw.FillOval (drawX (weaponPos.x), drawY (weaponPos.y), WEAPON_RAD - BORDER_W, WEAPON_RAD - BORDER_W, C_BACK)
	    weaponPos := endPos
	end if

	% Draw Player
	Draw.FillOval (drawX (collider.v.x), drawY (collider.v.y), PLAYER_RAD, PLAYER_RAD, colorType)
	Draw.FillOval (drawX (collider.v.x), drawY (collider.v.y), PLAYER_RAD - BORDER_W, PLAYER_RAD - BORDER_W, C_BACK)
    end draw

    % Generate fitness number
    fcn fitness () : real
	result bulletAmount * CO_BULLET + destroys * CO_DESTROYS + (timeSurvived / playerCount) * CO_TIME + (11 - place) * CO_PLACE
    end fitness

    % Generate danger number
    fcn danger (coWeapons, coBullets, coHealth, coReload : real) : real
	var r : real := 0
	for i : 1 .. WEAPON_MAX
	    r += WeaponType.rating (weaponTypes (i))
	end for
	if reloading then
	    result r * coWeapons + bulletAmount * coBullets + health * coHealth - coReload
	end if
	result r * coWeapons + bulletAmount * coBullets + health * coHealth
    end danger

    % Moves based on key input
    body proc move (d : int)
	accel := Vector.add (accel, DIRECTIONS (d))
	if accel.x = 0 and accel.y = 0 then
	    moved := false
	else
	    moved := true
	end if
    end move

    % Slows down (Friction)
    body proc stop ()
	Vector.lerp_zero (velocity, DECELERATION)
    end stop

    % Gets weapon stats
    body proc getWeapon ()
	t := weaponTypes (currentWeapon).t
	if t = KNIFE then
	    weaponStats := getKnife ()
	elsif t = PISTOL then
	    weaponStats := getPistol ()
	elsif t = SHOTGUN then
	    weaponStats := getShotgun ()
	elsif t = RIFLE then
	    weaponStats := getRifle ()
	elsif t = LASER then
	    weaponStats := getLaser ()
	elsif t = SNIPER then
	    weaponStats := getSniper ()
	end if

	if weaponTypes (currentWeapon).rarity = RARE then
	    getRare (weaponStats)
	elsif weaponTypes (currentWeapon).rarity = EPIC then
	    getEpic (weaponStats)
	end if

	attacking := false
	reloading := false
    end getWeapon

    % Weapon procedures
    % Attack based on weapon
    body proc attack ()
	if t = KNIFE then
	    knife := true
	    raycast -> initial (true, weaponPos, direction, weaponStats.knockBack, KNIFE, BASE_DELAY, weaponStats.damage, weaponStats.range)
	elsif t = SNIPER then
	    raycast -> initial (true, weaponPos, direction, weaponStats.knockBack, SNIPER, BASE_DELAY, weaponStats.damage, weaponStats.range)
	elsif t = PISTOL or t = RIFLE then
	    getProjectile () -> initial (true, weaponPos, direction, weaponStats.knockBack, weaponStats.damage, weaponStats.range)
	elsif t = SHOTGUN then
	    getProjectile () -> initial (true, weaponPos, direction + PI / 40, weaponStats.knockBack, weaponStats.damage, weaponStats.range)
	    getProjectile () -> initial (true, weaponPos, direction + PI / 10, weaponStats.knockBack, weaponStats.damage, weaponStats.range)
	    getProjectile () -> initial (true, weaponPos, direction - PI / 40, weaponStats.knockBack, weaponStats.damage, weaponStats.range)
	    getProjectile () -> initial (true, weaponPos, direction - PI / 10, weaponStats.knockBack, weaponStats.damage, weaponStats.range)
	elsif t = LASER then
	    laser
	end if
	weaponTypes (currentWeapon).clipAmount -= weaponStats.bulletLost
	velocity := Vector.add (velocity, Vector.make (weaponStats.recoil, direction + PI))
    end attack

    % Special procedure for laser fire
    body proc laser ()
	raycast -> initial (true, weaponPos, direction, weaponStats.knockBack, t, BASE_DELAY, weaponStats.damage, weaponStats.range)
    end laser

    % Reload weapon to full clip
    body proc reload ()
	if bulletAmount < weaponStats.maxClip - weaponTypes (currentWeapon).clipAmount then
	    weaponTypes (currentWeapon).clipAmount += (bulletAmount div weaponStats.bulletLost) * weaponStats.bulletLost
	    bulletAmount := bulletAmount mod weaponStats.bulletLost
	else
	    bulletAmount -= weaponStats.maxClip - weaponTypes (currentWeapon).clipAmount
	    weaponTypes (currentWeapon).clipAmount := weaponStats.maxClip
	end if
    end reload

    % Player death
    body proc destroy ()
	enabled := false
	clamp (health, 0, HEALTH)
	clamp (bulletAmount, 0, BULLETS)
	playerCount -= 1

	for i : 1 .. PROJ_MAX
	    projectiles (i) -> destroy
	end for
	raycast -> destroy

	var r : real := 0
	var ratings, inds : array 1 .. WEAPONI_MAX of real
	for i : 1 .. WEAPONI_MAX
	    ratings (i) := 0
	    inds (i) := 0
	end for
	for i : 1 .. WEAPON_MAX
	    r := WeaponType.rating (weaponTypes (i))
	    for j : 1 .. WEAPONI_MAX - 1
		if r > ratings (j) then
		    ratings (j + 1) := ratings (j)
		    ratings (j) := r
		    inds (j + 1) := inds (j)
		    inds (j) := i
		    r := 0
		end if
	    end for
	    if r > ratings (WEAPONI_MAX) then
		ratings (WEAPONI_MAX) := r
		inds (WEAPONI_MAX) := i
	    end if
	end for

	itemBox -> initial (true, Vector.sub (collider.v, Vector.comp (ITEM_W / 2, ITEM_H / 2)), bulletAmount, C_ITEM)
	for i : 1 .. WEAPONI_MAX
	    if weaponTypes (round (inds (i))).t ~= KNIFE then
		itemBox -> weaponTypes (i) := WeaponType.upgrade (weaponTypes (round (inds (i))))
	    end if
	end for
	itemBox -> update
	place := playerCount + 1
    end destroy

    % Finds the next inactive projectile
    body fcn getProjectile () : ^Projectile
	for i : 1 .. upper (projectiles)
	    if ~projectiles (i) -> enabled then
		result projectiles (i)
	    end if
	end for
	result nil (Projectile)
    end getProjectile
end Player
