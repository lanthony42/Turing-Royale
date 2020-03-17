%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% COVER OBSTACLE CLASS %%%%%
class Cover
    inherit Object
    export var all

    var health, colorType : int
    var radius : real

    forward proc destroy ()

    % Constructor
    proc initial (on : boolean, p : vector, c : int, r : real)
	enabled := on
	collider := Collide.make ('C', p, p, r)
	health := round (HEALTH + r - PLAYER_RAD)
	colorType := c
	radius := r
    end initial

    % Update value
    proc update ()
	collider.r := (health / (HEALTH + collider.r - PLAYER_RAD)) * (radius - BORDER_W) + BORDER_W
	if collider.r <= BORDER_W then
	    destroy
	end if
    end update

    % Render
    proc draw ()
	Draw.FillOval (drawX (collider.v.x), drawY (collider.v.y), round (collider.r), round (collider.r), colorType)
	Draw.FillOval (drawX (collider.v.x), drawY (collider.v.y), round (collider.r - BORDER_W), round (collider.r - BORDER_W), C_BACK)
    end draw

    % Destroys cover
    body proc destroy ()
	enabled := false
    end destroy
end Cover
