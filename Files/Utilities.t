%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% USEFUL MODULES %%%%%
module Constants
    export * ~.all

    const PI : real := 3.1415926535898
    const DEG_RAD : real := PI / 180
    const EPSILON : real := 0.001

    % Game Constants
    const BASE_DELAY : int := 32
    const WIDTH : int := 3000
    const HEIGHT : int := 2400
    const SCR_WIDTH : int := WIDTH div 4
    const SCR_HEIGHT : int := HEIGHT div 4
    const SCR_WH : int := SCR_WIDTH div 2
    const SCR_HH : int := SCR_HEIGHT div 2
    const BORDER_W : int := 5

    const M_PROJ : int := 2
    const M_LASER : int := 1
    const M_STOP : int := 3
    const MENU : int := -2
    const TUTORIAL : int := -1
    const SCORE : int := 0
    const MAIN : int := 1
    const END : int := 2

    % Quadtree Constants
    const QUAD_MAX : int := 4
    const QUAD_FIT : boolean := false
    const QUAD_SCALE : boolean := true

    % Player Constants
    const HEALTH : int := 100
    const ARMOR : int := 0
    const BULLETS : int := 300
    const MAX_SPEED : real := 9
    const ACCELERATION : real := 8
    const DECELERATION : real := 1

    const PLAYER_MAX : int := 10
    const PLAYER_RAD : int := 40

    const CO_BULLET : real := 0.1
    const CO_DESTROYS : real := 2
    const CO_TIME : real := 1
    const CO_PLACE : real := 10

    % AI Constants
    const NODE_MAX : int := 15
    const IN_MAX : int := 6
    const OUT_MAX : int := 7
    const ACTIVATION : real := 0.5

    const BASEW : int := 5
    const INPUT : int := 0
    const OUTPUT : int := 1
    const PLUSMIN : int := 2
    const PMHALF : int := 3

    const BIAS : int := 1
    const TARGET : int := 2
    const DANGER : int := 3
    const THREAT : int := 4
    const ONITEM : int := 5
    const ITEMSCR : int := 6

    const RELOAD : int := 7
    const ATTACK : int := 8
    const RTARGET : int := 9
    const RATARGET : int := 10
    const RRAND : int := 11
    const RITEM : int := 12
    const GITEM : int := 13

    const ITEMCTRL : int := 14
    const SAFETY : int := 15

    % Weapon Constants
    const WEAPON_MAX : int := 4
    const WEAPON_RAD : int := 10
    const ITEM_MAX : int := round (PLAYER_MAX * 1.2)
    const ITEM_W : int := 70
    const ITEM_H : int := 50
    const COMMON : int := 0
    const RARE : int := 1
    const EPIC : int := 2

    const NULL : int := -1
    const KNIFE : int := 0
    const PISTOL : int := 1
    const SHOTGUN : int := 2
    const RIFLE : int := 3
    const LASER : int := 4
    const SNIPER : int := 5

    const WEAPONI_MAX : int := 2
    const P_COMMON : int := 75
    const P_RARE : int := 95
    const P_EPIC : int := 100

    const P_PISTOL : int := 30
    const P_SHOTGUN : int := 55
    const P_RIFLE : int := 80
    const P_LASER : int := 92
    const P_SNIPER : int := 100

    const BULLET_LOW : int := 30
    const BULLET_HIGH : int := 50

    % Projectile Constants
    const PROJ_MAX : int := 6
    const PROJ_RAD : int := 3
    const PROJ_SPEED : real := 25

    % Ray Constants
    const RAY_W : int := 2
    const LASER_W : int := 8
    const LASER_WI : int := 4

    % Obstacle Constants
    const WALL_MAX : int := 44
    const COVER_MAX : int := 38

    % UI Constants
    const UI_HEALTH_X : int := SCR_WH div 2
    const UI_HEALTH_Y : int := 15
    const UI_HEALTH_W : int := SCR_WH
    const UI_HEALTH_H : int := 20

    const UI_INV_X : int := UI_HEALTH_X + UI_HEALTH_W + 30
    const UI_INV_WX : int := SCR_WIDTH - UI_HEALTH_Y
    const UI_INV_Y : int := SCR_HEIGHT - UI_HEALTH_Y
    const UI_INV_H : int := 60
    const UI_INV_W : int := 80

    const UI_NAMEBAR_Y : int := UI_HEALTH_Y + UI_HEALTH_H + BORDER_W * 2
    const UI_BULLET_W : int := round (SCR_WH * 0.8)
    const UI_HELPER_X : int := SCR_WH - 50
    const UI_HELPER_W : int := SCR_WH + 50
    const UI_HELPER_H : int := UI_HEALTH_Y + UI_INV_H + 40

    % Color Codes
    const C_BACK : int := maxcolor

    const C_YELLOW : int := maxcolor - 1
    const C_BLUE : int := maxcolor - 2
    const C_GREEN : int := maxcolor - 3
    const C_PURPLE : int := maxcolor - 4
    const C_ORANGE : int := maxcolor - 5
    const C_RED : int := maxcolor - 6
    const C_ORANGER : int := maxcolor - 7
    const C_GREENER : int := maxcolor - 8

    const C_PROJ : int := maxcolor - 9
    const C_LASER : int := maxcolor - 10
    const C_LASERI : int := maxcolor - 11
    const C_ITEM : int := maxcolor - 12
    const C_ITEMI : int := maxcolor - 13
    const C_UI : int := maxcolor - 14
    const C_GRAY : int := maxcolor - 15
end Constants

module Variables
    export var * ~.all

    var item : int := -1
    var ticks, playerCount : int := 0
    var player : int := 1
    var camX, camY, stage : int := 0
    var playerName : string := ""

    % Main color array
    var colorTypes : array 1 .. 7 of int
    colorTypes (1) := C_YELLOW
    colorTypes (2) := C_BLUE
    colorTypes (3) := C_GREEN
    colorTypes (4) := C_PURPLE
    colorTypes (5) := C_ORANGER
    colorTypes (6) := C_RED
    colorTypes (7) := C_GREENER

    % Base clip array
    var clipBase : array - 1 .. 5 of int
    clipBase (NULL) := NULL
    clipBase (KNIFE) := 1
    clipBase (PISTOL) := 4
    clipBase (SHOTGUN) := 12
    clipBase (RIFLE) := 7
    clipBase (LASER) := 10
    clipBase (SNIPER) := 3
end Variables

%%%%% UTILITIES %%%%%
module Helpers
    export * ~.all

    % Clamp integer
    proc clamp (var n : int, mn, mx : int)
	if n > mx then
	    n := mx
	elsif n < mn then
	    n := mn
	end if
    end clamp

    % Clamp real
    proc clamp_real (var n : real, mn, mx : real)
	if n > mx then
	    n := mx
	elsif n < mn then
	    n := mn
	end if
    end clamp_real

    % Round value from epsilon to nearest integer
    proc epsilon (var n : real)
	if abs (round (n) - n) <= EPSILON then
	    n := round (n)
	end if
    end epsilon

    % Draw on X camera axis
    fcn drawX (x : real) : int
	result round (x - camX)
    end drawX

    % Draw on Y camera axis
    fcn drawY (y : real) : int
	result round (y - camY)
    end drawY

    % Draw on scaled X axis
    fcn scaleX (x : real) : int
	result x div 4
    end scaleX

    % Draw on scaled Y axis
    fcn scaleY (y : real) : int
	result y div 4
    end scaleY
end Helpers

% Standard vector using radians
module Vector
    export comp, make, mag, dir, approx, add, sub, clamp_comp, clamp_mag, lerp_zero, normal, dir_points, d_product, str, * ~.vector

    type vector :
	record
	    x, y : real
	end record

    % Make vector from x and y composites
    fcn comp (x, y : real) : vector
	var v : vector
	v.x := x
	v.y := y
	result v
    end comp

    % Make vector from magnitude and direction
    fcn make (m, d : real) : vector
	var v : vector
	v.x := m * cos (d)
	v.y := m * sin (d)
	result v
    end make

    % Magnitude
    fcn mag (v : vector) : real
	result sqrt (v.x ** 2 + v.y ** 2)
    end mag

    % Direction
    fcn dir (v : vector) : real
	var o : real := 0
	if v.x ~= 0 then
	    o := arctan (v.y / v.x)
	else
	    o := PI / 2
	    if v.y < 0 then
		o += PI
	    end if
	end if
	if v.x < 0 then
	    o := PI + o
	end if
	loop
	    exit when o < 2 * PI
	    o -= 2 * PI
	end loop
	loop
	    exit when o >= 0
	    o += 2 * PI
	end loop
	result o
    end dir

    % Aproximate vector composites
    proc approx (var n : vector)
	epsilon (n.x)
	epsilon (n.y)
    end approx

    % Add two vectors
    fcn add (n, m : vector) : vector
	var v : vector
	v.x := n.x + m.x
	v.y := n.y + m.y
	Vector.approx (v)
	result v
    end add

    % Subtract two vectors
    fcn sub (n, m : vector) : vector
	var v : vector
	v.x := n.x - m.x
	v.y := n.y - m.y
	Vector.approx (v)
	result v
    end sub

    % Clamp vector composites
    proc clamp_comp (var n : vector, mnx, mxx, mny, mxy : real)
	clamp_real (n.x, mnx, mxx)
	clamp_real (n.y, mny, mxy)
	Vector.approx (n)
    end clamp_comp

    % Clamp vector magnitude
    proc clamp_mag (var n : vector, mn, mx : real)
	if Vector.mag (n) > mx then
	    n := Vector.make (mx, Vector.dir (n))
	elsif Vector.mag (n) < mn then
	    n := Vector.make (mn, Vector.dir (n))
	end if
	Vector.approx (n)
    end clamp_mag

    % Linearly interpolate towards zero
    proc lerp_zero (var n : vector, m : real)
	if Vector.mag (n) - m < 0 then
	    n := Vector.comp (0, 0)
	    return
	end if
	n := Vector.make (Vector.mag (n) - m, Vector.dir (n))
    end lerp_zero

    % Normalize vector
    fcn normal (n : vector) : vector
	var o : vector
	o.x := n.x / Vector.mag (n)
	o.y := n.y / Vector.mag (n)
	Vector.approx (o)
	result o
    end normal

    % Direction between two points
    fcn dir_points (n, m : vector) : real
	var v : vector
	v := Vector.sub (n, m)
	result Vector.dir (v)
    end dir_points

    % Dot product of two vectors
    fcn d_product (n, m : vector) : real
	result n.x * m.x + n.y * m.y
    end d_product

    % Vector to string
    fcn str (v : vector) : string
	result realstr (v.x, 5) + ", " + realstr (v.y, 5)
    end str
end Vector

% Collision shape used in each object
module Collide
    import Vector
    export comp, make, rayToRect, * ~.closePoint, * ~.Collider

    /*  For Rectangles, t = B, v is position of bottom left corner and w is the top right corner of the rectangle
     For Circles, t = C, v is position of the center and r = radius of the circle; t = 'M' for players ([M]ovables circles)
     For Rays, t = R, v is the starting position and w is the ending position; For TRays, r = radius
     For Points, t = P, v is the position, w is not used    */
    type Collider :
	record
	    t : char
	    v, w : vector
	    r : real
	end record

    % Make collider from real components
    fcn comp (t : char, x1, y1, x2, y2, r : real) : Collider
	var o : Collider
	o.t := t
	o.v := Vector.comp (x1, y1)
	o.w := Vector.comp (x2, y2)
	o.r := r
	result o
    end comp

    % Make collider from vectors
    fcn make (t : char, v, w : vector, r : real) : Collider
	var o : Collider
	o.t := t
	o.v := v
	o.w := w
	o.r := r
	result o
    end make

    % Convert ray collider to rectangle collider
    fcn rayToRect (r : Collider) : Collider
	var o : Collider
	o.t := 'B'

	if r.v.x < r.w.x then
	    o.v.x := r.v.x
	    o.w.x := r.w.x
	else
	    o.v.x := r.w.x
	    o.w.x := r.v.x
	end if
	if r.v.y < r.w.y then
	    o.v.y := r.v.y
	    o.w.y := r.w.y
	else
	    o.v.y := r.w.y
	    o.w.y := r.v.y
	end if

	o.v := Vector.sub (o.v, Vector.comp (r.r, r.r))
	o.w := Vector.add (o.w, Vector.comp (r.r, r.r))
	result o
    end rayToRect

    % Closest point on line to given point
    fcn closePoint (v : vector, c : Collider) : vector
	var A1 : real := c.w.y - c.v.y
	var B1 : real := c.v.x - c.w.x
	var C1 : real := A1 * c.v.x + B1 * c.v.y
	var C2 : real := -B1 * v.x + A1 * v.y
	var det : real := A1 ** 2 - (-B1) * B1
	var o : vector
	if det ~= 0 then
	    o.x := (A1 * C1 - B1 * C2) / det
	    o.y := (A1 * C2 - (-B1) * C1) / det
	else
	    o.x := v.x
	    o.y := v.y
	end if
	result o
    end closePoint
end Collide

module WeaponType
    export rating, upgrade, null, knife, /* Tests */ tP, tR, tSh, tL, tSn,
    /**/ * ~.wType

    type wType :
	record
	    t, rarity, clipAmount : int
	end record

    % Generates rating score
    fcn rating (w : wType) : real
	result (w.t + 1) * (w.rarity ** 2 + 1)
    end rating

    % Upgrades rarity of weapon
    fcn upgrade (t : wType) : wType
	var w : wType := t
	w.rarity += 1
	clamp (w.rarity, COMMON, EPIC)
	result w
    end upgrade

    % Returns a null weapon
    fcn null () : wType
	var w : wType
	w.t := NULL
	w.rarity := NULL
	w.clipAmount := clipBase (NULL)
	result w
    end null

    % Returns default knife weapon
    fcn knife () : wType
	var w : wType
	w.t := KNIFE
	w.rarity := COMMON
	w.clipAmount := clipBase (KNIFE)
	result w
    end knife

    % Tests
    fcn tP () : wType
	var w : wType
	w.t := PISTOL
	w.rarity := COMMON
	w.clipAmount := clipBase (PISTOL)
	result w
    end tP

    fcn tSh () : wType
	var w : wType
	w.t := SHOTGUN
	w.rarity := COMMON
	w.clipAmount := clipBase (SHOTGUN)
	result w
    end tSh

    fcn tR () : wType
	var w : wType
	w.t := RIFLE
	w.rarity := COMMON
	w.clipAmount := clipBase (RIFLE)
	result w
    end tR

    fcn tL () : wType
	var w : wType
	w.t := LASER
	w.rarity := COMMON
	w.clipAmount := clipBase (LASER)
	result w
    end tL

    fcn tSn () : wType
	var w : wType
	w.t := SNIPER
	w.rarity := COMMON
	w.clipAmount := clipBase (SNIPER)
	result w
    end tSn
end WeaponType

module WeaponStats
    export * ~.all

    type wStats :
	record
	    mvmtSpeed, delayAmount, reloadDelay, recoil, knockBack : real
	    damage, bulletLost, maxClip, range : int
	end record

    % Knife Stats
    fcn getKnife () : wStats
	var o : wStats
	o.mvmtSpeed := 0.9
	o.delayAmount := 0.5
	o.reloadDelay := 0

	o.damage := 5
	o.bulletLost := 0
	o.maxClip := 1
	o.range := 20
	o.recoil := 0
	o.knockBack := 1.2
	result o
    end getKnife

    % Pistol Stats
    fcn getPistol () : wStats
	var o : wStats
	o.mvmtSpeed := 0.85
	o.delayAmount := 0.2
	o.reloadDelay := 1

	o.damage := 10
	o.bulletLost := 1
	o.maxClip := 12
	o.range := 375
	o.recoil := 3
	o.knockBack := 1.7
	result o
    end getPistol

    % Shotgun Stats
    fcn getShotgun () : wStats
	var o : wStats
	o.mvmtSpeed := 0.75
	o.delayAmount := 0.6 % Keep high to avoid running out of projectiles
	o.reloadDelay := 1.5

	o.damage := 5
	o.bulletLost := 4
	o.maxClip := 24
	o.range := 325
	o.recoil := 4
	o.knockBack := 2
	result o
    end getShotgun

    % Rifle Stats
    fcn getRifle () : wStats
	var o : wStats
	o.mvmtSpeed := 0.8
	o.delayAmount := 0.1
	o.reloadDelay := 1.8

	o.damage := 12
	o.bulletLost := 1
	o.maxClip := 25
	o.range := 550
	o.recoil := 3
	o.knockBack := 3
	result o
    end getRifle

    % Laser Stats
    fcn getLaser () : wStats
	var o : wStats
	o.mvmtSpeed := 0.65
	o.delayAmount := 0.5
	o.reloadDelay := 2.4

	o.damage := 2
	o.bulletLost := 2
	o.maxClip := 20
	o.range := 350
	o.recoil := 1.02
	o.knockBack := 1.05
	result o
    end getLaser

    % Sniper Stats
    fcn getSniper () : wStats
	var o : wStats
	o.mvmtSpeed := 0.7
	o.delayAmount := 0.75
	o.reloadDelay := 2.2

	o.damage := 22
	o.bulletLost := 1
	o.maxClip := 12
	o.range := 900
	o.recoil := 2
	o.knockBack := 4
	result o
    end getSniper

    % Rare weapons Stats
    proc getRare (var w : wStats)
	w.mvmtSpeed += 0.05
	w.reloadDelay -= 0.1

	w.damage += 2
	w.maxClip += w.bulletLost
	w.range += 10
	w.recoil -= 0.5
	clamp_real (w.recoil, 0, 10)
    end getRare

    % Epic weapons Stats
    proc getEpic (var w : wStats)
	w.mvmtSpeed += 0.1
	w.reloadDelay -= 0.2

	w.damage += 4
	w.maxClip += w.bulletLost * 2
	w.range += 25
	w.recoil -= 1
	clamp_real (w.recoil, 0, 10)
    end getEpic
end WeaponStats

module Directional
    import Vector
    export var * ~.all

    % Store directions for movement
    var DIRECTIONS : array 1 .. 4 of vector
    DIRECTIONS (1) := Vector.comp (0, 1)
    DIRECTIONS (2) := Vector.comp (1, 0)
    DIRECTIONS (3) := Vector.comp (0, -1)
    DIRECTIONS (4) := Vector.comp (-1, 0)
end Directional

