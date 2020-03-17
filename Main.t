%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Course Code  : ICS3U
% Course Sec   : 6
% First Name   : Anthony
% Last Name    : Louie
% Program Name : Turing Royale
% Description  : A 2D Battle Royale Styled Shooter with multiple weapon types and bot AI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% MAIN FILES %%%%%
include "files/Utilities.t"
include "files/Classes/Object.t"
include "files/Classes/Item.t"
include "files/Classes/Wall.t"
include "files/Classes/Cover.t"

include "files/Classes/Projectile.t"
include "files/Classes/Raycast.t"
include "files/Classes/Player.t"
include "files/Classes/AIControl.t"

include "files/Collision.t"
include "files/Classes/Quadtree.t"

include "files/Update.t"
include "files/Input.t"

setscreen ("graphics:" + intstr (SCR_WIDTH) + ";" + intstr (SCR_HEIGHT) + ",nocursor,nobuttonbar,noecho")
View.Set ("offscreenonly,title:Turing Royale")

%%%%% MAIN CODE %%%%%

% Main game loop
initColor
initInput
getScore
loop
    % Menu code
    stage := MENU
    loop
	exit when menuInput ()

	if stage = MENU then
	    menuDraw
	elsif stage = TUTORIAL then
	    tutDraw
	elsif stage = SCORE then
	    scoreDraw
	end if

	View.UpdateArea (0, 0, maxx, maxy)
	cls
	delay (BASE_DELAY)
    end loop

    % Initialization code
    getName
    initial
    initUI

    % Main game code
    stage := MAIN
    startTime := Time.Elapsed
    loop
	ticks := Time.Elapsed

	% Input
	exit when playerInput ()

	% Update variable calculations (including clamping)
	update
	updateCam

	% Rendering
	draw
	updateUI
	View.UpdateArea (0, 0, maxx, maxy)
	cls

	% Exit condition
	exit when playerCount <= 1

	% Decrease delay based on time taken for processing
	put "\n\n", (ticks - Time.Elapsed) % Debug
	delay (BASE_DELAY + (ticks - Time.Elapsed))
    end loop

    % End of game code
    stage := END
    loop
	exit when afterInput ()

	% Rendering
	draw
	updateUI
	View.UpdateArea (0, 0, maxx, maxy)
	cls

	delay (BASE_DELAY)
    end loop
    updateScore
end loop
