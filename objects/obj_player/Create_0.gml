
enum LEVEL {
	EMPTY,
	WALL,
	LADDER
}

#region Physics

	hspd = 0;
	vspd = 0;
	acc = 0.2;
	spd = 4;
	grav = 0.25;
	jumpforce = 5;
	
	wallDir = 0;

#endregion

#region Control

	hdir = 0;
	vdir = 0;
	jreleased = true;

#endregion

#region Finite State Machine

	// Creating the FSM component
	FSM = new FiniteStateMachine();
	
	// Idle state
	var idleState = new State("Idle", spr_player);
	idleState.StepEvent = function() {
		hspd = Approach(hspd, 0, acc);
	    
	    if (!CheckTileCollision(x, y + grav, LEVEL.WALL) && !CheckTileCollision(x, y + grav, LEVEL.LADDER)) FSM.Set("Fall");
	    else {
	    	if (hdir!=0) FSM.Set("Run");
	    	if (vdir<0 && jreleased) FSM.Set("Jump");
	    }
	    //if (CheckTilePixel(x, y-10, LEVEL.LADDER) && (vdir<0)) FSM.Set("Ladder");
	    //if (CheckTilePixel(x, y+4, LEVEL.LADDER) && (vdir>0)) FSM.Set("Ladder");
	};
	
	// Running state
	var runState = new State("Run", spr_player);
	runState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, acc);
	    
	    if (!CheckTileCollision(x, y + grav, LEVEL.WALL) && !CheckTileCollision(x, y + grav, LEVEL.LADDER)) FSM.Set("Fall");
	    else {
	    	if (hdir==0) FSM.Set("Idle");
	    	if (vdir<0 && jreleased) FSM.Set("Jump");
	    }
	    	//if (CheckTilePixel(x, y-1, LEVEL.LADDER) && (vdir!=0)) FSM.Set("Ladder");
	    //if (CheckTilePixel(x, y+1, LEVEL.LADDER) && (vdir>0)) FSM.Set("Ladder");
	};
	
	// Falling state
	var fallState = new State("Fall", spr_player);
	fallState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, acc * 2);
		vspd += grav;
	    
	    if (CheckTileCollision(x, y + vspd, LEVEL.WALL) || (CheckTilePixel(x, y + vspd, LEVEL.LADDER)))
	    	FSM.Set((hdir==0)?"Idle":"Run");
	    else if (CheckTileCollision(x + hspd, y, LEVEL.WALL) && (hdir==sign(hspd)))
	    	FSM.Set("Wall");
	    if (CheckTilePixel(x, y + vdir, LEVEL.LADDER) && (vdir!=0))
	    	FSM.Set("Ladder");
	};
	
	// Jumping state
	var jumpState = new State("Jump", spr_player);
	jumpState.StateBeginEvent = function() {
		vspd -= jumpforce;
		jreleased = false;
	};
	
	jumpState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, acc);
		vspd += grav;
	    
	    if (vspd > 0) FSM.Set("Fall");
	    //if (CheckTilePixel(x, y+2, LEVEL.LADDER) && (vdir!=0)) FSM.Set("Ladder");
	};
	
	// Ladder state
	var ladderState = new State("Ladder", spr_player);
	ladderState.StateBeginEvent = function() {
		vspd = 0;
		hspd = 0;
	};
	
	ladderState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, acc);
		vspd = Approach(vspd, spd * vdir / 2, acc);
		jreleased = false;
		if (hdir==0) {
			hspd = 0;
			x = Approach(x, 16*(x div 16) + sprite_xoffset, 1);
		}
	    
	    if (!CheckTileCollision(x, y, LEVEL.LADDER)) FSM.Set("Idle");
	};
	
	// WallJump state
	var wallState = new State("Wall", spr_player);
	wallState.StateBeginEvent = function() {
		wallDir = hdir;
		hspd = 0;
		if (vspd>0) vspd = 0;
		x = 16*(x div 16) + sprite_xoffset;
	};
	
	wallState.StepEvent = function() {
		vspd += (vspd<0)?grav:grav/10;
		
		if (hdir!=wallDir || !CheckTileCollision(x + wallDir, y, LEVEL.WALL)) FSM.Set("Fall");
		if (CheckTileCollision(x, y + grav, LEVEL.WALL)) FSM.Set("Idle");
		if (vdir<0 && jreleased) FSM.Set("Jump");
	};

	// Setting Run as the first state
	FSM.Set("Idle");

#endregion