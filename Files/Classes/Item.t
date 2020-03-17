%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% BASE PICKUP ITEM CLASS %%%%%
class Item
    inherit Object
    import WeaponType
    export var all

    var weaponTypes : array 1 .. WEAPONI_MAX of wType
    var bulletAmount, colorType : int
    var bullets, weapons : boolean

    % Constructor
    proc initial (on : boolean, p : vector, b, c : int)
	enabled := on
	collider := Collide.make ('I', p, Vector.add (p, Vector.comp (ITEM_W, ITEM_H)), 0)
	bulletAmount := b
	colorType := c
	bullets := false
	weapons := false

	for i : 1 .. WEAPONI_MAX
	    weaponTypes (i) := WeaponType.null ()
	end for
    end initial

    % Update value
    proc update ()
	bullets := bulletAmount > 0
	weapons := false
	for i : 1 .. WEAPONI_MAX
	    weapons := weapons or weaponTypes (i).t ~= NULL
	end for
	if ~ (bullets or weapons) then
	    enabled := false
	end if
    end update

    % Render
    proc draw ()
	Draw.FillBox (drawX (collider.v.x), drawY (collider.v.y), drawX (collider.w.x), drawY (collider.w.y), colorType)
	Draw.FillBox (drawX (collider.v.x + BORDER_W), drawY (collider.v.y + BORDER_W), drawX (collider.w.x - BORDER_W), drawY (collider.w.y - BORDER_W), C_ITEMI)

	if weapons and bulletAmount > 35 then
	    Draw.Text ("!", drawX (collider.v.x + ITEM_W div 2) - 3, drawY (collider.w.y - ITEM_H div 2) - 11, Font.New ("sans serif:22:bold"), colorType)
	elsif weapons then
	    Draw.Text ("~", drawX (collider.v.x + ITEM_W div 2) - 8, drawY (collider.w.y - ITEM_H div 2) - 11, Font.New ("sans serif:22:bold"), colorType)
	elsif bullets then
	    Draw.Text ("?", drawX (collider.v.x + ITEM_W div 2) - 9, drawY (collider.w.y - ITEM_H div 2) - 11, Font.New ("sans serif:22:bold"), colorType)
	end if
    end draw

    % Randomize item values
    proc random ()
	var r : int
	for i : 1 .. WEAPONI_MAX
	    r := Rand.Int (1, 100)
	    if r <= P_COMMON then
		weaponTypes (i).rarity := COMMON
	    elsif r <= P_RARE then
		weaponTypes (i).rarity := RARE
	    else
		weaponTypes (i).rarity := EPIC
	    end if

	    r := Rand.Int (1, 100)
	    if r <= P_PISTOL then
		weaponTypes (i).t := PISTOL
	    elsif r <= P_SHOTGUN then
		weaponTypes (i).t := SHOTGUN
	    elsif r <= P_RIFLE then
		weaponTypes (i).t := RIFLE
	    elsif r <= P_LASER then
		weaponTypes (i).t := LASER
	    else
		weaponTypes (i).t := SNIPER
	    end if

	    weaponTypes (i).clipAmount := clipBase (weaponTypes (i).t)
	    bulletAmount += Rand.Int (BULLET_LOW, BULLET_HIGH) - round (WeaponType.rating (weaponTypes (i)))
	end for
    end random
end Item
