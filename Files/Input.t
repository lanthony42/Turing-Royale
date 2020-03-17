%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% INPUT HANDLING %%%%%
module InputHandler
    import Input, Mouse, Vector, Collide
    export * ~.all

    var chars, oldChars : array char of boolean
    var mouse_x, mouse_y, mouse_b, oldMouse_b, change, curWeapon : int
    var dummy : boolean

    forward fcn changeWeapon (c : int) : boolean

    % Initialize oldChars
    proc initInput ()
	Input.KeyDown (chars)
	oldChars := chars
	oldMouse_b := 0
	buttonOver := NULL
    end initInput

    % Input in menu stage
    fcn menuInput () : boolean
	Input.KeyDown (chars)

	if chars ('t') or chars ('T') then
	    if ~oldChars ('t') and ~oldChars ('T') then
		if stage = TUTORIAL then
		    stage := MENU
		elsif stage = MENU then
		    stage := TUTORIAL
		end if
	    end if
	end if
	if chars ('s') or chars ('S') then
	    if ~oldChars ('s') and ~oldChars ('S') then
		if stage = SCORE then
		    stage := MENU
		elsif stage = MENU then
		    stage := SCORE
		end if
	    end if
	end if

	oldChars := chars
	result chars ('p') or chars ('P')
    end menuInput

    % Get input for current player
    fcn playerInput () : boolean
	Input.KeyDown (chars)
	Mouse.Where (mouse_x, mouse_y, mouse_b)

	if players (player) -> enabled then
	    % On key press
	    if chars ('w') or chars ('W') then
		players (player) -> move (1)
	    end if
	    if chars ('a') or chars ('A') then
		players (player) -> move (4)
	    end if
	    if chars ('s') or chars ('S') then
		players (player) -> move (3)
	    end if
	    if chars ('d') or chars ('D') then
		players (player) -> move (2)
	    end if

	    % Weapon Choice
	    if chars ('1') then
		dummy := changeWeapon (0)
	    end if
	    if chars ('2') then
		dummy := changeWeapon (1)
	    end if
	    if chars ('3') then
		dummy := changeWeapon (2)
	    end if
	    if chars ('4') then
		dummy := changeWeapon (3)
	    end if
	    if chars ('5') then
		dummy := changeWeapon (4)
	    end if
	    % On key up
	    if ( ~chars ('q') and oldChars ('q')) or ( ~chars ('Q') and oldChars ('Q')) then
		change := players (player) -> currentWeapon - 1
		loop
		    if change < 0 then
			change := WEAPON_MAX
		    end if
		    exit when changeWeapon (change)
		    change -= 1
		end loop
	    end if
	    if ( ~chars ('e') and oldChars ('e')) or ( ~chars ('E') and oldChars ('E')) then
		change := players (player) -> currentWeapon + 1
		loop
		    exit when changeWeapon (change mod (WEAPON_MAX + 1))
		    change += 1
		end loop
	    end if

	    % Directional and attacking events
	    players (player) -> direction := Vector.dir_points (Vector.sub (players (player) -> collider.v, Vector.comp (camX, camY)), Vector.comp (mouse_x, mouse_y)) + PI
	    for i : 0 .. upper (buttons)
		if rectPoint (buttons (i), Collide.comp ('P', mouse_x, mouse_y, 0, 0, 0)) then
		    buttonOver := i
		    exit
		else
		    buttonOver := NULL
		end if
	    end for
	    if mouse_b = 1 or chars (' ') then
		% Check UI collision
		if mouse_b = 1 and buttonOver < 5 and buttonOver ~= NULL and (showInv or (showItem and players (player) -> itemCollide)) then
		    dummy := changeWeapon (buttonOver)
		elsif mouse_b = 1 and buttonOver ~= NULL and (showItem and players (player) -> itemCollide) then
		    if buttonOver = upper (buttons) then
			if players (player) -> bulletAmount + players (player) -> onItem -> bulletAmount > BULLETS then
			    players (player) -> onItem -> bulletAmount -= BULLETS - players (player) -> bulletAmount
			    players (player) -> bulletAmount := BULLETS
			else
			    players (player) -> bulletAmount += players (player) -> onItem -> bulletAmount
			    players (player) -> onItem -> bulletAmount := 0
			end if
		    elsif oldMouse_b = 0 and buttonOver > 4 then % Swap weapons
			for i : 1 .. WEAPON_MAX
			    if players (player) -> weaponTypes (i).t = NULL then
				curWeapon := i
				exit
			    else
				curWeapon := players (player) -> currentWeapon
			    end if
			end for
			var playerW : wType := players (player) -> weaponTypes (curWeapon)
			if playerW.t ~= KNIFE then
			    players (player) -> weaponTypes (curWeapon) := players (player) -> onItem -> weaponTypes (buttonOver - WEAPON_MAX)
			    players (player) -> onItem -> weaponTypes (buttonOver - WEAPON_MAX) := playerW
			end if
			players (player) -> getWeapon
		    end if
		else
		    % Click to shoot
		    if players (player) -> t = PISTOL or players (player) -> t = SNIPER then
			if oldMouse_b = 0 and ~oldChars (' ') then
			    players (player) -> attacking := true
			end if
		    else
			players (player) -> attacking := true
		    end if
		end if
	    end if

	    % Reloading
	    if chars ('r') or chars ('R') then
		players (player) -> reloading := true
	    end if
	    % Open inventory
	    if chars ('i') or chars ('I') or chars (KEY_TAB) then
		if ~oldChars ('i') and ~oldChars ('I') and ~oldChars (KEY_TAB) then
		    showInv := ~showInv
		end if
	    end if
	    % Open items
	    if chars ('f') or chars ('F') then
		if ~oldChars ('f') and ~oldChars ('F') then
		    showItem := ~showItem
		end if
	    end if

	    oldChars := chars
	    oldMouse_b := mouse_b
	else
	    result chars (KEY_ENTER)
	end if
	result false
    end playerInput

    % Input in end stage
    fcn afterInput () : boolean
	Input.KeyDown (chars)
	result chars (KEY_ENTER)
    end afterInput

    % Change weapons for current player
    body fcn changeWeapon (c : int) : boolean
	if players (player) -> weaponTypes (c).t ~= NULL then
	    players (player) -> currentWeapon := c
	    players (player) -> getWeapon
	    result true
	end if
	result false
    end changeWeapon
end InputHandler
