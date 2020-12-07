
enum LEVEL {
	EMPTY,
	WALL,
	LADDER
}

#region Physics

	hspd = 0;
	vspd = 0;
	
	groundAcc = 0.3;
	groundFricc = 0.1;
	
	airAcc = 0.2;
	airFricc = 0.02;
	
	spd = 3;
	grav = 0.15;
	jumpforce = 3.5;
	collisionOffset = 8;
	
	wallDir = 0;
	ladderX = 0;

#endregion

#region Control

	hdir = 0;
	vdir = 0;
	jreleased = true;
	grab = false;
	grabreleased = true;

#endregion

#region Finite State Machine

	// Creating the FSM component
	FSM = new FiniteStateMachine();
	
	// ===============================================
	// ---------------- Idle state -------------------
	// ===============================================
	var idleState = new State("Idle", spr_player);
	
	idleState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?groundAcc:groundFricc);
	};
	
	idleState.StateTransitions = function() {
	    if (hdir!=0 && !CheckTileCollision(x + hdir, y, LEVEL.WALL)) FSM.Set("Run");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	    if (!CheckTileCollision(x, y + 1, LEVEL.WALL) && !CheckTileCollision(x, y + 1, LEVEL.LADDER)) FSM.Set("Coyote");
	    if (CheckTileCollision(x, y + vdir, LEVEL.LADDER) && (vdir!=0)) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Running state ----------------
	// ===============================================
	var runState = new State("Run", spr_player);
	
	runState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?groundAcc:groundFricc);
	};
	
	runState.StateTransitions = function() {
	    if (hspd==0 && hdir==0) FSM.Set("Idle");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	    if (!CheckTileCollision(x, y + 1, LEVEL.WALL) && !CheckTileCollision(x, y + 1, LEVEL.LADDER)) FSM.Set("Coyote");
	    if (CheckTileCollision(x, y+vdir, LEVEL.LADDER) && (vdir!=0)) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Coyote state ----------------
	// ===============================================
	var coyoteState = new State("Coyote", spr_player);
	coyoteState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?airAcc:airFricc);
		vspd += grav;
	};
	
	coyoteState.StateTransitions = function() {
	    if (grab && (CheckTileCollision(x + 1, y, LEVEL.WALL) || CheckTileCollision(x - 1, y, LEVEL.WALL))) FSM.Set("Wall");
	    if (vspd==0) FSM.Set((hdir==0)?"Idle":"Run");
	    if (FSM.framesInState > 5) FSM.Set("Fall");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	    if (vdir!=0 && jreleased && CheckTileCollision(x, y + vdir, LEVEL.LADDER)) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Falling state ----------------
	// ===============================================
	var fallState = new State("Fall", spr_player);
	fallState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?airAcc:airFricc);
		vspd += grav;
	};
	
	fallState.StateTransitions = function() {
	    if (grab && (CheckTileCollision(x + 1, y, LEVEL.WALL) || CheckTileCollision(x - 1, y, LEVEL.WALL))) FSM.Set("Wall");
	    if (vspd==0) FSM.Set((hdir==0)?"Idle":"Run");
	    if (vdir!=0 && jreleased && CheckTileCollision(x, y + vdir, LEVEL.LADDER)) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Jumping state ----------------
	// ===============================================
	var jumpState = new State("Jump", spr_player);
	
	jumpState.StateBeginEvent = function() {
		vspd -= jumpforce;
		jreleased = false;
	};
	
	jumpState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?airAcc:airFricc);
		vspd = min(1, vspd + grav*(1 + jreleased));
	};
	
	jumpState.StateTransitions = function() {
	    if (vspd > 0) FSM.Set("Fall");
	    if (grab && (CheckTileCollision(x + 1, y, LEVEL.WALL) || CheckTileCollision(x - 1, y, LEVEL.WALL))) FSM.Set("Wall");
	    if (vdir!=0 && jreleased && CheckTileCollision(x, y, LEVEL.LADDER)) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Ladder state -----------------
	// ===============================================
	var ladderState = new State("Ladder", spr_player);
	
	ladderState.StateBeginEvent = function() {
		y += vdir;
		hspd = 0;
		var ladderDir = (CheckTileCollision(x + 16, y, LEVEL.LADDER) - CheckTileCollision(x - 16, y, LEVEL.LADDER));
		ladderX = 8 + 16*((x + 8 * ladderDir) div 16);
	};
	
	ladderState.StepEvent = function() {
		hspd = Approach(hspd, 0.5*spd * hdir, abs(hdir)?groundAcc:groundFricc);
		vspd = Approach(vspd, spd * vdir / 2, abs(hdir)?groundAcc:groundFricc);
		if (hdir==0) {
			x = Approach(x, ladderX, 1);
		}
	};
	
	ladderState.StateEndEvent = function() {
		vspd = 0;
		jreleased = false;
	};
	
	ladderState.StateTransitions = function() {
	    if (!CheckTileCollision(x, y, LEVEL.LADDER)) {
	    	FSM.Set("Idle");
	    	if (!CheckTileCollision(x, y + 1, LEVEL.WALL) && !CheckTileCollision(x, y + 1, LEVEL.LADDER)) FSM.Set("Fall");
	    }
	};
	
	// ===============================================
	// ---------------- Wall state ---------------
	// ===============================================
	var wallState = new State("Wall", spr_player);
	
	wallState.StateBeginEvent = function() {
		wallDir = CheckTileCollision(x + 1, y, LEVEL.WALL) - CheckTileCollision(x - 1, y, LEVEL.WALL);
		grabreleased = false;
		if (vspd>0) vspd = 0;
	};
	
	wallState.StepEvent = function() {
		vspd += (vspd<0)?grav:grav/4;
	};
	
	wallState.StateTransitions = function() {
		if (!grab || !CheckTileCollision(x + wallDir, y, LEVEL.WALL)) FSM.Set("Fall");
		if (CheckTileCollision(x, y + 1, LEVEL.WALL)) FSM.Set("Idle");
		if (vdir<0 && jreleased) FSM.Set("WallJump");
	};
	
	// ===============================================
	// ---------------- WallJump state ---------------
	// ===============================================
	var wallJumpState = new State("WallJump", spr_player);
	
	wallJumpState.StateBeginEvent = function() {
		hspd = spd * -wallDir;
		vspd = -jumpforce;
		jreleased = false;
	};
	
	wallJumpState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, acc);
		vspd += grav;
	};
	
	wallJumpState.StateTransitions = function() {
	    if (vspd > 0) FSM.Set("Fall");
	    if (grab && CheckTileCollision(x + hdir, y, LEVEL.WALL)) FSM.Set("Wall");
	    if (CheckTileCollision(x, y+vdir, LEVEL.LADDER) && (vdir!=0)) FSM.Set("Ladder");
	};

	// Setting Run as the first state
	FSM.Set("Idle");

#endregion