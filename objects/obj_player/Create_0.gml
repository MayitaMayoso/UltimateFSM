
enum LEVEL {
	EMPTY,
	WALL,
	LADDER = 99
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
	
	plummetSpd = 5;
	plummetTime = 8;

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
	    if (hdir!=0 && !CheckGround(hdir, 0)) FSM.Set("Run");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	    if (!CheckGround(0, 1)) FSM.Set("Coyote");
	    if (CheckLadder(0, 1) && (vdir>0)) FSM.Set("Ladder");
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
	    if (!CheckGround(0, 1)) FSM.Set("Coyote");
	    if (CheckLadder(0, 1) && (vdir>0)) FSM.Set("Ladder");
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
	    if (grab && (CheckGround(1, 0) || CheckGround(-1, 0))) FSM.Set("Wall");
	    if (vdir > 0) FSM.Set("Plummet");
	    if (vspd==0) FSM.Set((hdir==0)?"Idle":"Run");
	    if (FSM.framesInState > 5) FSM.Set("Fall");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	    if (vdir!=0 && jreleased && CheckLadder()) FSM.Set("Ladder");
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
	    if (grab && (CheckGround(1, 0) || CheckGround(-1, 0))) FSM.Set("Wall");
	    if (vdir > 0) FSM.Set("Plummet");
	    if (vspd==0) FSM.Set((hdir==0)?"Idle":"Run");
	    if (vdir!=0 && jreleased && CheckLadder()) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Plummet state ----------------
	// ===============================================
	var plummetState = new State("Plummet", spr_player);
	plummetState.StateBeginEvent = function() {
		hspd = 0;
		vspd = 0;
		image_angle = 360;
	};
	
	plummetState.StepEvent = function() {
		if (FSM.framesInState == plummetTime) {
			vspd = plummetSpd;
			image_angle = 0;
		} else {
			image_angle = lerp(image_angle, 0, 0.3);
		}
	};
	
	plummetState.StateTransitions = function() {
	    if (vspd==0 && FSM.framesInState>plummetTime) FSM.Set("Idle");
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
	    if (vdir > 0) FSM.Set("Plummet");
	    if (grab && (CheckGround(1, 0) || CheckGround(-1, 0))) FSM.Set("Wall");
	    if (vdir!=0 && jreleased && CheckLadder()) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Ladder state -----------------
	// ===============================================
	var ladderState = new State("Ladder", spr_player);
	
	ladderState.StateBeginEvent = function() {
		y += vdir;
		hspd = 0;
		var ladderDir = (CheckLadder(16, 0) - CheckLadder(-16, 0));
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
		jreleased = false;
		while(CheckLadder()) {
			x += sign(hspd);
			y += sign(vspd);
		}
		vspd = 0;
	};
	
	ladderState.StateTransitions = function() {
	    if (!CheckLadder(hspd, vspd)) {
	    	FSM.Set("Idle");
	    	if (!CheckGround(0, 1) && !CheckLadder(0, 1)) FSM.Set("Fall");
	    }
	};
	
	// ===============================================
	// ---------------- Wall state ---------------
	// ===============================================
	var wallState = new State("Wall", spr_player);
	
	wallState.StateBeginEvent = function() {
		wallDir = CheckGround(1, 0) - CheckGround(-1, 0);
		grabreleased = false;
		if (vspd>0) vspd = 0;
	};
	
	wallState.StepEvent = function() {
		vspd += (vspd<0)?grav:grav/4;
	};
	
	wallState.StateTransitions = function() {
		if (!grab || !CheckGround(wallDir, 0)) FSM.Set("Fall");
		if (CheckGround(0, 1)) FSM.Set("Idle");
		if (vdir<0 && jreleased) FSM.Set("WallJump");
	};
	
	// ===============================================
	// ---------------- WallJump state ---------------
	// ===============================================
	var wallJumpState = new State("WallJump", spr_player);
	
	wallJumpState.StateBeginEvent = function() {
		hspd = 2*jumpforce * -wallDir;
		vspd = -jumpforce;
		jreleased = false;
	};
	
	wallJumpState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?groundAcc:groundFricc);
		vspd += grav;
	};
	
	wallJumpState.StateTransitions = function() {
	    if (vspd > 0) FSM.Set("Fall");
	    if (vdir > 0) FSM.Set("Plummet");
	    if (grab && (CheckGround(1, 0) || CheckGround(-1, 0))) FSM.Set("Wall");
	    if (CheckLadder() && (vdir!=0)) FSM.Set("Ladder");
	};

	// Setting Run as the first state
	FSM.Set("Idle");

#endregion

#region Checkers

	groundTile = layer_tilemap_get_id(layer_get_id("Ground"));
	laddersTile = layer_tilemap_get_id(layer_get_id("Ladders"));

	CheckGround = function(xmov, ymov) {
		xmov = DefaultValue(xmov, 0);
		ymov = DefaultValue(ymov, 0);
		var ground = CheckTileCollision(x+xmov, y+ymov, groundTile);
		var ladder = (	ymov >0 && FSM.name != "Ladder"
						&& CheckTileCollision(x+xmov, y+ymov, laddersTile)
						&& !CheckTileCollision(x, y, laddersTile) );
						
		return (ground || ladder);
	};
	
	CheckLadder = function(xmov, ymov) {
		xmov = DefaultValue(xmov, 0);
		ymov = DefaultValue(ymov, 0);
		return CheckTileCollision(x+xmov, y+ymov, laddersTile);
	};

#endregion