%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PROJECTILE CLASS %%%%%
class Projectile
    inherit Object
    export var all

    var velocity : vector
    var direction, knockback : real
    var damage, distance, range : int

    forward proc destroy ()

    % Constructor
    proc initial (on : boolean, p : vector, dir, k : real, dmg, r : int)
	enabled := on
	collider := Collide.make ('P', p, p, 0)
	direction := dir
	knockback := k
	velocity := Vector.make (PROJ_SPEED, direction)
	distance := 0
	damage := dmg
	range := r
    end initial

    % Update value
    proc update ()
	if distance > range then
	    destroy
	end if
	collider.w := collider.v
	collider.v := Vector.add (collider.v, velocity)
	distance += round (PROJ_SPEED)
    end update

    % Render
    proc draw ()
	Draw.FillOval (drawX (collider.v.x), drawY (collider.v.y), PROJ_RAD, PROJ_RAD, C_PROJ)
    end draw

    % Destroys at range
    body proc destroy ()
	enabled := false
    end destroy
end Projectile
