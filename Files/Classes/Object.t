%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code: ICS3U
% Course Sec : 6
% First Name : Anthony
% Last Name  : Louie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% BASE CLASS %%%%%
class Object
    import Math, Vector, Collide
    export var all
    
    % Base variable
    var uid : int
    var enabled : boolean := false
    var collider : Collider
end Object
