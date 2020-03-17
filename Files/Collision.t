%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% COLLISION TESTING %%%%%
module Collision
    import Math, Vector, Collide, Player, Projectile
    export var * ~.all

    forward fcn circleMCircle (n : Collider, var m : Collider) : boolean
    forward fcn rayTRay (n : Collider, var m : Collider) : boolean
    forward fcn rayAARay (n, m : Collider) : boolean

    % Checks if ranges overlap
    fcn rangeOverlap (p, q : vector) : boolean
	result p.x <= q.y and p.y >= q.x
    end rangeOverlap

    % Rectangle / rectangle collision
    fcn rectRect (n, m : Collider) : boolean
	result rangeOverlap (Vector.comp (n.v.x, n.w.x), Vector.comp (m.v.x, m.w.x)) and rangeOverlap (Vector.comp (n.v.y, n.w.y), Vector.comp (m.v.y, m.w.y))
    end rectRect

    % Rectangle / circle collision
    fcn rectCircle (n, m : Collider) : boolean
	var test : vector := m.v
	if n.v.x > m.v.x then % Left
	    test.x := n.v.x
	elsif n.w.x < m.v.x then % Right
	    test.x := n.w.x
	end if
	if n.v.y > m.v.y then % Bottom
	    test.y := n.v.y
	elsif n.w.y < m.v.y then % Top
	    test.y := n.w.y
	end if

	result (m.v.x - test.x) ** 2 + (m.v.y - test.y) ** 2 <= m.r ** 2
    end rectCircle

    % Rectangle / Movable circles (ie. players) collision
    fcn rectMCircle (n : Collider, var m : Collider) : boolean
	if rectCircle (n, m) then
	    var corner : boolean := true
	    var offset : vector := Vector.comp (0, 0)
	    var test : vector := m.v

	    if n.v.x > m.w.x then % Left
		test.x := n.v.x
		offset.x -= m.r
	    elsif n.w.x < m.w.x then % Right
		test.x := n.w.x
		offset.x += m.r
	    else
		corner := false
	    end if
	    if n.v.y > m.w.y then % Bottom
		test.y := n.v.y
		offset.y -= m.r
	    elsif n.w.y < m.w.y then % Top
		test.y := n.w.y
		offset.y += m.r
	    else
		corner := false
	    end if

	    if corner then
		corner := circleMCircle (Collide.make ('C', test, Vector.comp (0, 0), 0), m)
	    else
		m.v := Vector.add (test, offset)
	    end if
	    m.w := m.v
	    result true
	end if
	result false
    end rectMCircle

    % Rectangle / point collision
    fcn rectPoint (n, m : Collider) : boolean
	result m.v.x <= n.w.x and m.v.x >= n.v.x and m.v.y <= n.w.y and m.v.y >= n.v.y
    end rectPoint

    % Rectangle / ray collision
    fcn rectRay (n : Collider, var m : Collider) : boolean
	var o : boolean := false
	if rayAARay (m, Collide.make ('R', n.v, Vector.comp (n.v.x, n.w.y), 0)) then
	    o := rayTRay (Collide.make ('R', n.v, Vector.comp (n.v.x, n.w.y), 0), m) or o
	end if
	if rayAARay (m, Collide.make ('R', n.v, Vector.comp (n.w.x, n.v.y), 0)) then
	    o := rayTRay (Collide.make ('R', n.v, Vector.comp (n.w.x, n.v.y), 0), m) or o
	end if
	if rayAARay (m, Collide.make ('R', Vector.comp (n.w.x, n.v.y), n.w, 0)) then
	    o := rayTRay (Collide.make ('R', Vector.comp (n.w.x, n.v.y), n.w, 0), m) or o
	end if
	if rayAARay (m, Collide.make ('R', Vector.comp (n.v.x, n.w.y), n.w, 0)) then
	    o := rayTRay (Collide.make ('R', Vector.comp (n.v.x, n.w.y), n.w, 0), m) or o
	end if
	result o
    end rectRay

    % Approximate rectangle / rectangle collision for node placement
    fcn rectRay_p (n, m : Collider) : boolean
	result rectRect (n, Collide.rayToRect (m))
    end rectRay_p

    % Circle / circle collision types
    fcn circleCircle (n, m : Collider) : boolean
	result (m.v.x - n.v.x) ** 2 + (m.v.y - n.v.y) ** 2 <= (m.r + n.r) ** 2
    end circleCircle

    % Rectangle / Movable circles (ie. players) collision
    body fcn circleMCircle (n : Collider, var m : Collider) : boolean
	if circleCircle (n, m) then
	    var v : vector := Vector.sub (n.v, m.v)
	    var k : real := (n.r + m.r) / sqrt (v.x ** 2 + v.y ** 2)

	    v.y *= k - 1
	    v.x *= k - 1

	    m.v := Vector.sub (m.v, v)
	    result true
	end if
	result false
    end circleMCircle

    % Player / Player overlap management
    fcn mcircleMCircle (var n, m : Collider) : boolean
	if circleCircle (n, m) then
	    var v : vector := Vector.sub (n.v, m.v)
	    var k : real := (n.r + m.r) / sqrt (v.x ** 2 + v.y ** 2)

	    v.y *= (k - 1) / 2
	    v.x *= (k - 1) / 2

	    n.v := Vector.add (n.v, v)
	    m.v := Vector.sub (m.v, v)
	    result true
	end if
	result false
    end mcircleMCircle

    % Circle / ray collision
    fcn circleRay (n : Collider, var m : Collider) : boolean
	var r : real := n.r + m.r

	if Math.DistancePointLine (n.v.x, n.v.y, m.v.x, m.v.y, m.w.x, m.w.y) <= r then
	    var c : vector := Vector.sub (n.v, m.v)
	    var v : vector := Vector.sub (m.w, m.v)
	    if Vector.mag (v) = 0 then
		result false
	    end if
	    var d : real := Vector.d_product (c, Vector.normal (v))
	    if d <= 0 then
		result false
	    end if
	    m.w := Vector.add (m.v, Vector.make (d - sqrt (r ** 2 - (c.x ** 2 + c.y ** 2 - d ** 2)), Vector.dir (v)))
	    result true
	end if
	result false
    end circleRay

    % Basic ray / ray collision, no thickness
    fcn rayRay (n, m : Collider, var v : vector) : boolean
	var A1 : real := n.w.y - n.v.y
	var B1 : real := n.v.x - n.w.x
	var C1 : real := A1 * n.v.x + B1 * n.v.y
	var A2 : real := m.w.y - m.v.y
	var B2 : real := m.v.x - m.w.x
	var C2 : real := A2 * m.v.x + B2 * m.v.y

	var det : real := A1 * B2 - A2 * B1
	if det ~= 0 then
	    v.x := (B2 * C1 - B1 * C2) / det
	    v.y := (A1 * C2 - A2 * C1) / det
	    if v.x >= min (n.v.x, n.w.x) and v.x <= max (n.v.x, n.w.x)
		    and v.x >= min (m.v.x, m.w.x) and v.x <= max (m.v.x, m.w.x)
		    and v.y >= min (n.v.y, n.w.y) and v.y <= max (n.v.y, n.w.y)
		    and v.y >= min (m.v.y, m.w.y) and v.y <= max (m.v.y, m.w.y) then
		result true
	    end if
	    result false
	end if
	v := Vector.comp (-1, -1)
	result false
    end rayRay

    % Ray / Thick Ray collision, Ray 1 (n) should not have thickness
    body fcn rayTRay (n : Collider, var m : Collider) : boolean
	var v : vector
	var p : boolean := rayRay (n, m, v)
	var d : real := Math.Distance (v.x, v.y, m.v.x, m.v.y)

	var t : vector := closePoint (m.v, n)
	var f : real := Math.Distance (t.x, t.y, m.v.x, m.v.y)
	if f ~= 0 then
	    f := d - (d * m.r / f)
	else
	    f := d
	end if
	v := Vector.add (m.v, Vector.make (f, Vector.dir_points (m.w, m.v)))
	var c : vector := closePoint (v, n)

	if round (Math.Distance (v.x, v.y, c.x, c.y)) <= m.r
		and c.x >= min (n.v.x, n.w.x) and c.x <= max (n.v.x, n.w.x)
		and c.y >= min (n.v.y, n.w.y) and c.y <= max (n.v.y, n.w.y)
		and v.x >= min (m.v.x, m.w.x) and v.x <= max (m.v.x, m.w.x)
		and v.y >= min (m.v.y, m.w.y) and v.y <= max (m.v.y, m.w.y) then
	    m.w := v
	    result true
	elsif circleRay (n, m) or circleRay (Collide.make ('C', n.w, Vector.comp (0, 0), 0), m) then
	    result true
	end if
	result false
    end rayTRay

    % Thick ray collision with collision time (For Player / Player)
    fcn trayTRay (var n, m : Collider) : boolean
	var v : vector := Vector.sub (n.w, n.v)
	var c : vector := Vector.sub (m.w, m.v)
	var d : vector := Vector.sub (v, c)
	var r : Collider := Collide.make ('R', n.v, Vector.add (n.v, d), n.r)

	if circleRay (m, r) then
	    var t : real := Vector.mag (Vector.sub (r.w, r.v)) / Vector.mag (d)
	    n.w := Vector.add (n.v, Vector.make (Vector.mag (v) * t, Vector.dir (v)))
	    m.w := Vector.add (m.v, Vector.make (Vector.mag (c) * t, Vector.dir (c)))
	    result true
	else
	    result false
	end if
    end trayTRay

    % Approximate Ray / AARay collision, n may have thickness
    body fcn rayAARay (n, m : Collider) : boolean
	result rectRect (Collide.rayToRect (n), Collide.rayToRect (m))
    end rayAARay

    fcn inNode (n, m : Collider) : boolean
	if m.t = 'B' or m.t = 'I' then
	    result rectRect (n, m)
	elsif m.t = 'C' or m.t = 'M' then
	    result rectCircle (n, m)
	elsif m.t = 'P' then
	    result rectPoint (n, m)
	elsif m.t = 'R' then
	    result rectRay_p (n, m)
	end if
	result false
    end inNode

    % Player collision management
    fcn playerCollision (var p, o : Collider) : boolean
	if o.t = 'B' then % Walls
	    result rectMCircle (o, p)
	elsif o.t = 'C' then % Cover
	    result circleMCircle (o, p)
	elsif o.t = 'M' then % Other players
	    result mcircleMCircle (o, p)
	elsif o.t = 'I' then % Item
	    result rectCircle (o, p)
	end if
	result false
    end playerCollision

    % AI collision management
    fcn playerAICollision (var r, o : Collider) : boolean
	if o.t = 'B' then % Walls
	    result rectRay (o, r)
	end if
	result false
    end playerAICollision

    % Projectile collision management
    fcn projCollision (p, o : Collider) : boolean
	if o.t = 'B' then % Walls
	    result rectPoint (o, p)
	elsif o.t = 'C' or o.t = 'M' then % Cover / Player
	    result circleCircle (o, p)
	end if
	result false
    end projCollision

    % Ray collision management
    fcn rayCollision (p, o : Collider, var w : vector) : boolean
	var r : Collider := p
	var output : boolean := false

	if o.t = 'B' then % Walls
	    output := rectRay (o, r)
	elsif o.t = 'C' or o.t = 'M' then % Cover / Players
	    output := circleRay (o, r)
	end if

	if (r.v.x - w.x) ** 2 + (r.v.y - w.y) ** 2 > (r.v.x - r.w.x) ** 2 + (r.v.y - r.w.y) ** 2 then
	    output := true
	    w := r.w
	else
	    output := false
	end if
	result output
    end rayCollision
end Collision
