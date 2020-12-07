FSM.StepEvent();

// Controls
hdir = keyboard_check(vk_right) - keyboard_check(vk_left);
vdir = keyboard_check(vk_down) - (keyboard_check(vk_up) || keyboard_check(vk_space));
if (vdir>=0) jreleased = true;
grab = keyboard_check(ord("Z"));
if (!grab) grabreleased = true;

// Horizontal Collisions
if (CheckTileCollision(x + hspd, y, LEVEL.WALL)) {
	while(!CheckTileCollision(x + sign(hspd), y, LEVEL.WALL)) {
		x += sign(hspd);
	}
	hspd = 0;
}

// Vertical Collisions
if (CheckTileCollision(x, y + vspd, LEVEL.WALL)) {
	// Correct position in corners when falling
	var corrected = false;
	if ( vspd<0 ) {
		var dir = 1;
		repeat(2) {
			var off = 0;
			while(CheckTileCollision(x+off, y + vspd, LEVEL.WALL) && abs(off) < collisionOffset) {
				off += dir;
			}
			if (abs(off)<collisionOffset) {
				x+=off;
				corrected = true;
				break;
			}
			dir = -1;
		}
	}
	
	// Adjust position to collision
	if (!corrected) {
		while(!CheckTileCollision(x, y + sign(vspd), LEVEL.WALL)) {
			y += sign(vspd);
		}
		vspd = 0;
		}
}

// One way collision
if (vspd>0 && FSM.current.name != "Ladder" && vdir<=0) {
	
	// Adjust position to collision
	if (!CheckTileCollision(x, y, LEVEL.LADDER) && CheckTileCollision(x, y + vspd, LEVEL.LADDER)) {
		while(!CheckTileCollision(x, y + 1, LEVEL.LADDER)) {
			y ++;
		}
		vspd = 0;
	}
}

x += hspd;
y += vspd;

// Fix position if stuck on the wall
if ( CheckTileCollision(x, y, LEVEL.WALL) ) {
	var checking_direction = 0;
	var checking_precission = 45;
	var check_x = x;
	var check_y = y;
	var checking_distance = 1;
	var current_iter = 0;
	
	// While our current position is stuck in a wall
	while (CheckTileCollision(check_x, check_y, LEVEL.WALL) && current_iter<300) {
		// Check in a circle which is the closest free position
		// If there is no free position in the circle increase the circle radius
		checking_direction = (checking_direction+checking_precission)%360;
		checking_distance++;
		current_iter++;
	
		// Calculate the new checking positions
		check_x = x+lengthdir_x(checking_distance, checking_direction);
		check_y = y+lengthdir_y(checking_distance, checking_direction);
	}

	x = check_x;
	y = check_y;
}

if (mouse_check_button_pressed(mb_left)) {
	x = mouse_x;
	y = mouse_y;
}
