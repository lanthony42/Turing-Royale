%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% WALL OBSTACLE CLASS %%%%%
class Wall
    inherit Object
    export var all

    var colorType : int
    var innerP, innerD : vector

    % Constructor
    proc initial (on : boolean, p, d : vector, c : int, edge : string)
	enabled := on
	collider := Collide.make ('B', p, d, 0)

	% Where each char represents a side ('0' for no edge, '1' for edge)
	% Starts at North, going clockwise
	innerP := p
	innerD := d
	for i : 1 .. 4
	    if edge (i) = '1' then
		if i = 1 then
		    innerD.y -= BORDER_W
		elsif i = 2 then
		    innerD.x -= BORDER_W
		elsif i = 3 then
		    innerP.y += BORDER_W
		elsif i = 4 then
		    innerP.x += BORDER_W
		end if
	    end if
	end for

	colorType := c
    end initial

    % Render
    proc draw ()
	Draw.FillBox (drawX (collider.v.x), drawY (collider.v.y), drawX (collider.w.x), drawY (collider.w.y), colorType)
	Draw.FillBox (drawX (innerP.x), drawY (innerP.y), drawX (innerD.x), drawY (innerD.y), C_BACK)
    end draw
end Wall
