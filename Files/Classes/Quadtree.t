%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% QUADTREE CLASS %%%%%
class Quadtree
    import Math, Vector, Collide, Object
    export all

    % Single node
    type node :
	record
	    area : Collider
	    objects : array 1 .. QUAD_MAX of ^Object
	    nw, ne, se, sw : ^node
	    isLeaf : boolean
	    count : int
	end record

    var root : ^node
    var leafCount : int
    var output : string

    forward proc initNode (var n : node, p, d : vector)
    forward proc split (var n : node)

    % Initialize tree
    proc initTree ()
	new root
	initNode ( ^root, Vector.comp (0, 0), Vector.comp (WIDTH, HEIGHT))
	leafCount := 1
	output := ""
    end initTree

    % Initialize single tree
    body proc initNode (var n : node, p, d : vector)
	n.area := Collide.make ("B", p, d, 0)
	for i : 1 .. QUAD_MAX
	    n.objects (i) := nil (Object)
	end for

	n.nw := nil
	n.ne := nil
	n.se := nil
	n.sw := nil
	n.isLeaf := true
	n.count := 0
    end initNode

    % Recursivly insert item into node
    proc insertInNode (var n : node, o : ^Object)
	if inNode (n.area, o -> collider) then
	    if n.isLeaf then
		if n.count >= QUAD_MAX then
		    split (n)
		    % Place current objects into children nodes
		    for j : 1 .. QUAD_MAX
			insertInNode ( ^ (n.nw), n.objects (j))
			insertInNode ( ^ (n.ne), n.objects (j))
			insertInNode ( ^ (n.se), n.objects (j))
			insertInNode ( ^ (n.sw), n.objects (j))
			n.objects (j) := nil
		    end for
		    n.count += 1
		    insertInNode ( ^ (n.nw), o)
		    insertInNode ( ^ (n.ne), o)
		    insertInNode ( ^ (n.se), o)
		    insertInNode ( ^ (n.sw), o)
		else
		    for i : 1 .. QUAD_MAX
			if n.objects (i) = nil then
			    n.count += 1
			    n.objects (i) := o
			    exit
			end if
		    end for
		end if
	    else
		n.count += 1
		insertInNode ( ^ (n.nw), o)
		insertInNode ( ^ (n.ne), o)
		insertInNode ( ^ (n.se), o)
		insertInNode ( ^ (n.sw), o)
	    end if
	end if
    end insertInNode

    % Insert item from root of tree
    proc insert (o : ^Object)
	if leafCount >= 50 then
	    Error.Halt ("Nodes Split Error")
	else
	    insertInNode ( ^root, o)
	end if
    end insert

    % Recursivly search for item in node
    proc searchNode (var n : node, o : ^Object, var inStr : string)
	if inNode (n.area, o -> collider) then
	    if n.isLeaf then
		for i : 1 .. QUAD_MAX
		    if n.objects (i) ~= nil and n.objects (i) -> uid ~= o -> uid then
			var uid : string := intstr (n.objects (i) -> uid, 3)
			if index (inStr, uid) = 0 then
			    inStr += uid
			end if
		    end if
		end for
	    else
		searchNode ( ^ (n.nw), o, inStr)
		searchNode ( ^ (n.ne), o, inStr)
		searchNode ( ^ (n.se), o, inStr)
		searchNode ( ^ (n.sw), o, inStr)
	    end if
	end if
    end searchNode

    % Search for item from root of tree, returns all possible collision items
    fcn search (o : ^Object) : string
	var output : string := ""
	searchNode ( ^root, o, output)
	result output
    end search

    % Split a node into four
    body proc split (var n : node)
	if n.isLeaf then
	    var h : vector := Vector.comp (n.area.v.x + (n.area.w.x - n.area.v.x) / 2, n.area.v.y + (n.area.w.y - n.area.v.y) / 2)
	    n.isLeaf := false
	    leafCount += 3

	    new n.nw
	    new n.ne
	    new n.se
	    new n.sw
	    initNode ( ^ (n.nw), Vector.comp (n.area.v.x, h.y), Vector.comp (h.x, n.area.w.y))
	    initNode ( ^ (n.ne), h, n.area.w)
	    initNode ( ^ (n.se), Vector.comp (h.x, n.area.v.y), Vector.comp (n.area.w.x, h.y))
	    initNode ( ^ (n.sw), n.area.v, h)
	end if
    end split

    % Recursivly draw nodes onto screen
    proc drawNode (n : node)
	if n.isLeaf then
	    if QUAD_FIT then
		% Fits quadtree into screen
		drawbox (scaleX (n.area.v.x), scaleY (n.area.v.y), scaleX (n.area.w.x), scaleY (n.area.w.y), white)
		% Text drawing
		Draw.Text (intstr (n.count), scaleX (n.area.v.x) + 2, scaleY (n.area.w.y) - 12, defFontID, white)
	    end if
	    if QUAD_SCALE then
		% Draws quadtree normally with camera scale
		drawbox (drawX (n.area.v.x), drawY (n.area.v.y), drawX (n.area.w.x), drawY (n.area.w.y), white)
		% Text drawing
		Draw.Text (intstr (n.count), drawX (n.area.v.x) + 2, drawY (n.area.w.y) - 12, defFontID, white)
	    end if
	else
	    drawNode ( ^ (n.nw))
	    drawNode ( ^ (n.ne))
	    drawNode ( ^ (n.se))
	    drawNode ( ^ (n.sw))
	end if
    end drawNode

    % Draws quadtree
    proc draw ()
	drawNode ( ^root)
    end draw

    % Recursivly frees node memory
    proc deleteNode (var n : node)
	if n.isLeaf then
	    return
	else
	    deleteNode ( ^ (n.nw))
	    free n.nw
	    deleteNode ( ^ (n.ne))
	    free n.ne
	    deleteNode ( ^ (n.se))
	    free n.se
	    deleteNode ( ^ (n.sw))
	    free n.sw
	end if
    end deleteNode

    % Deletes nodes from root
    proc delete ()
	if ~root -> isLeaf then
	    deleteNode ( ^root)
	end if
    end delete
end Quadtree
