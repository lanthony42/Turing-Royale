%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% WEAPON RAYCAST CLASS %%%%%
class Raycast
    inherit Object
    export var all

    var direction, knockback : real
    var weaponType, delayAmount, damage, range, timer : int

    forward proc destroy ()

    % Constructor
    proc initial (on : boolean, p : vector, dir, k : real, t, d, dmg, r : int)
	enabled := on
	direction := dir
	knockback := k
	weaponType := t
	delayAmount := d
	damage := dmg
	range := r
	timer := 0

	if weaponType = LASER then
	    collider := Collide.make ('R', p, Vector.add (p, Vector.make (r, direction)), LASER_W)
	else
	    collider := Collide.make ('R', p, Vector.add (p, Vector.make (r, direction)), 0)
	end if
    end initial

    % Update values
    proc update (t : int, p : vector, dir : real)
	if timer > delayAmount or weaponType ~= t then
	    destroy
	else
	    timer += BASE_DELAY
	end if

	weaponType := t
	collider.v := p
	direction := dir
	collider.w := Vector.add (collider.v, Vector.make (range, direction))
    end update

    % Render
    proc draw ()
	if weaponType = KNIFE then
	    Draw.ThickLine (drawX (collider.v.x), drawY (collider.v.y), drawX (collider.w.x), drawY (collider.w.y), RAY_W * 2, grey)
	elsif weaponType = LASER then
	    Draw.ThickLine (drawX (collider.v.x), drawY (collider.v.y), drawX (collider.w.x), drawY (collider.w.y), LASER_W, C_LASER)
	    Draw.ThickLine (drawX (collider.v.x), drawY (collider.v.y), drawX (collider.w.x), drawY (collider.w.y), LASER_WI, C_LASERI)
	Draw.ThickLine (drawX (collider.v.x), drawY (collider.v.y), drawX (collider.w.x), drawY (collider.w.y), 1, brightred)
	    elsif weaponType = SNIPER then
	    Draw.ThickLine (drawX (collider.v.x), drawY (collider.v.y), drawX (collider.w.x), drawY (collider.w.y), RAY_W, C_PROJ)
	end if
    end draw

    % Destroys ray after time
    body proc destroy ()
	enabled := false
	timer := 0
    end destroy
end Raycast
