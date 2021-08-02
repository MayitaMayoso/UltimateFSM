
enum LEVEL {
	EMPTY,
	WALL,
	LADDER = 99
}
image_xscale = .7;
image_yscale = .7;
#region Physics

	hspd = 0;
	vspd = 0;
	
	groundAcc = 0.3;
	groundFricc = 0.1;
	
	airAcc = 0.2;
	airFricc = 0.02;
	
	spd = 2;
	grav = 0.05;
	jumpforce = 2.5;
	collisionOffset = 8;
	
	wallDir = 0;
	ladderX = 0;
	
	plummetSpd = 3.4;
	plummetTime = 8;

#endregion

#region Control

	hdir = 0;
	vdir = 0;
	jreleased = true;
	grab = false;
	grabreleased = true;
	chargeArrow = false;
	chargeArrowReleased = true;

#endregion

#region Finite State Machine

	// Creating the FSM component
	FSM = new FiniteStateMachine();
	
	FSM.DirectionFunc = function() {
		if (hdir!=0) FSM.direction = sign(hdir);
	};
	
	// ===============================================
	// ---------------- Idle state -------------------
	// ===============================================
	idleState = new State("Idle");
	idleState.animation.Init(spr_archer_idle, .25);
	
	idleState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?groundAcc:groundFricc);
	};
	
	idleState.StepEndEvent = function() {
		if (chargeArrow && chargeArrowReleased) FSM.Set("ArrowCharge");
	    if (hdir!=0 && !CheckGround(hdir, 0)) FSM.Set("Run");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	    if (!CheckGround(0, 1)) FSM.Set("Fall");
	    if (CheckLadder(0, vdir) && (vdir!=0)) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Land state -------------------
	// ===============================================
	landState = new State("Land");
	landState.animation.Init(spr_archer_land, .25);
	
	landState.StateBeginEvent = function() {
		FSM.image.xscale = 1.2;
		FSM.image.yscale = 0.8;
	};
	
	landState.StepEvent = function() {
		if (FSM.previous.name != "Plummet")
			hspd = Approach(hspd, spd * hdir, abs(hdir)?groundAcc:groundFricc);
	};
	
	landState.StepEndEvent = function() {
		if (landState.animation.finished) FSM.Set("Idle");
		if (hdir!=0 && FSM.previous.name != "Plummet") FSM.Set("Run");
		if (chargeArrow && chargeArrowReleased && FSM.previous.name != "Plummet") FSM.Set("ArrowCharge");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	};
	
	// ===============================================
	// ---------------- Running state ----------------
	// ===============================================
	runState = new State("Run");
	runState.animation.Init(spr_archer_run, .2);
	
	runState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?groundAcc:groundFricc);
		runState.animation.speed = .2 * abs(hspd) / spd;
	};
	
	runState.StepEndEvent = function() {
	    if (hdir==0 && hspd==0) FSM.Set("Idle");
		if (chargeArrow && chargeArrowReleased) FSM.Set("ArrowCharge");
	    if (vdir<0 && jreleased) FSM.Set("Jump");
	    if (!CheckGround(0, 1)) FSM.Set("Fall");
	    if (CheckLadder(0, vdir) && (vdir!=0)) FSM.Set("Ladder");
	};
	
	// ===============================================
	// ---------------- Falling state ----------------
	// ===============================================
	fallState = new State("Fall");
	fallState.animation.Init(spr_archer_fall, .1, false);
	
	fallState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?airAcc:airFricc);
		vspd += grav;
	};
	
	fallState.StepEndEvent = function() {
	    if (grab && (CheckGround(1, 0) || CheckGround(-1, 0))) FSM.Set("Wall");
	    if (vdir > 0) FSM.Set("Plummet");
	    if (vdir < 0 && FSM.framesInState < 8 && IsIn(FSM.previous.name,["Idle","Run"])) FSM.Set("Jump");
	    if (vspd==0 && CheckGround(0, 1)) FSM.Set((hdir==0)?"Land":"Run");
	    if (vdir!=0 && jreleased && CheckLadder()) FSM.Set("Ladder");
		if (chargeArrow && chargeArrowReleased) FSM.Set("ArrowCharge");
	};
	
	// ===============================================
	// ---------------- Plummet state ----------------
	// ===============================================
	plummetState = new State("Plummet");
	plummetState.animation.Init(spr_archer_plummet, .4, false);
	
	plummetState.StateBeginEvent = function() {
		hspd = 0;
		vspd = 0;
	};
	
	plummetState.AnimationEndEvent = function() {
		vspd = plummetSpd;
	};
	
	plummetState.StepEndEvent = function() {
		FSM.image.xscale = .9;
		FSM.image.yscale = 1.1;
	    if (vspd==0 && plummetState.animation.finished) FSM.Set("Land");
	};
	
	// ===============================================
	// ---------------- Jumping state ----------------
	// ===============================================
	jumpState = new State("Jump");
	jumpState.animation.Init(spr_archer_jump, .15, false);
	
	jumpState.StateBeginEvent = function() {
		vspd -= jumpforce;
		jreleased = false;
		FSM.image.xscale = 0.8;
		FSM.image.yscale = 1.2;
	};
	
	jumpState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?airAcc:airFricc);
		vspd = min(1, vspd + grav*(1 + jreleased));
	};
	
	jumpState.StepEndEvent = function() {
	    if (vspd > 0) FSM.Set("Fall");
	    if (vdir > 0) FSM.Set("Plummet");
	    if (grab && (CheckGround(1, 0) || CheckGround(-1, 0))) FSM.Set("Wall");
	    if (vdir!=0 && jreleased && CheckLadder()) FSM.Set("Ladder");
		if (chargeArrow && chargeArrowReleased) FSM.Set("ArrowCharge");
	};
	
	// ===============================================
	// ---------------- Ladder state -----------------
	// ===============================================
	ladderState = new State("Ladder");
	ladderState.animation.Init(spr_archer_idle, 0);
	
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
	
	ladderState.StepEndEvent = function() {
	    if (!CheckLadder(hspd, vspd)) {
	    	FSM.Set("Idle");
	    	if (!CheckGround(0, 1) && !CheckLadder(0, 1)) FSM.Set("Fall");
	    }
	};
	
	// ===============================================
	// ---------------- Wall state ---------------
	// ===============================================
	wallState = new State("Wall");
	wallState.animation.Init(spr_archer_idle, 0);
	
	wallState.StateBeginEvent = function() {
		wallDir = CheckGround(1, 0) - CheckGround(-1, 0);
		grabreleased = false;
		if (vspd>0) vspd = 0;
	};
	
	wallState.StepEvent = function() {
		vspd += (vspd<0)?grav:grav/4;
	};
	
	wallState.StepEndEvent = function() {
		if (!grab || !CheckGround(wallDir, 0)) FSM.Set("Fall");
		if (CheckGround(0, 1)) FSM.Set("Idle");
		if (vdir<0 && jreleased) FSM.Set("WallJump");
	};
	
	// ===============================================
	// ---------------- WallJump state ---------------
	// ===============================================
	wallJumpState = new State("WallJump");
	wallJumpState.animation.Init(spr_archer_jump, .25, false);
	
	wallJumpState.StateBeginEvent = function() {
		hspd = 2*jumpforce * -wallDir;
		vspd = -jumpforce;
		jreleased = false;
		FSM.image.xscale = 1.5;
		FSM.image.yscale = 0.5;
	};
	
	wallJumpState.StepEvent = function() {
		hspd = Approach(hspd, spd * hdir, abs(hdir)?groundAcc:groundFricc);
		vspd += grav;
	};
	
	wallJumpState.StepEndEvent = function() {
	    if (vspd > 0) FSM.Set("Fall");
	    if (vdir > 0) FSM.Set("Plummet");
	    if (grab && (CheckGround(1, 0) || CheckGround(-1, 0))) FSM.Set("Wall");
	    if (CheckLadder() && (vdir!=0)) FSM.Set("Ladder");
		if (chargeArrow && chargeArrowReleased) FSM.Set("ArrowCharge");
	};
	
	// ===============================================
	// -------------- Arrow charge state -------------
	// ===============================================
	arrowChargeState = new State("ArrowCharge");
	arrowChargeState.animation.Init(spr_archer_arrow_charge, .25, false);
	
	arrowChargeState.StepEvent = function() {
		hspd = Approach(hspd, 0, groundFricc);
		vspd += grav;
	};
	
	arrowChargeState.StepEndEvent = function() {
		if (!chargeArrow) {
			if (arrowChargeState.animation.frame==arrowChargeState.animation.number-1) FSM.Set("ArrowRelease");
			else {
				FSM.Set(abs(hdir)?"Run":"Idle");
	    		if (!CheckGround(0, 1)) FSM.Set("Fall");
			}
		}
	};
	
	// ===============================================
	// -------------- Arrow release state ------------
	// ===============================================
	arrowReleaseState = new State("ArrowRelease");
	arrowReleaseState.animation.Init(spr_archer_arrow_release, .2, false);
	
	arrowReleaseState.StepEvent = function() {
		hspd = Approach(hspd, 0, groundFricc);
	};
	
	arrowReleaseState.StateBeginEvent = function() {
		var arr = instance_create_depth(x + 8*FSM.image.facing, y-14, depth-1, obj_arrow);
		arr.dir = FSM.image.facing;
	};
	
	arrowReleaseState.AnimationEndEvent = function() {
		FSM.Set(abs(hdir)?"Run":"Idle");
	    if (!CheckGround(0, 1)) FSM.Set("Fall");
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