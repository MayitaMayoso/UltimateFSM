FSM.StepEvent();

// Controls
hdir = keyboard_check(vk_right) - keyboard_check(vk_left);
vdir = keyboard_check(vk_down) - (keyboard_check(vk_up) || keyboard_check(vk_space));
if (vdir>=0) jreleased = true;
grab = keyboard_check(ord("Z"));
if (!grab) grabreleased = true;

// Horizontal Collisions
if (CheckGround(hspd, 0)) {
	while(!CheckGround(sign(hspd), 0)) {
		x += sign(hspd);
	}
	hspd = 0;
}

// Vertical Collisions
if (CheckGround(0, vspd)) {
	// Correct position in corners when falling
	var corrected = false;
	if ( vspd<0 ) {
		var dir = 1;
		repeat(2) {
			var off = 0;
			while(CheckGround(off, vspd) && (abs(off) < collisionOffset) ) {
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
		while(!CheckGround(0, sign(vspd))) {
			y += sign(vspd);
		}
		vspd = 0;
	}
}

x += hspd;
y += vspd;

// Fix position if stuck on the wall
if (CheckGround() && FSM.name != "Ladder") {
	var checking_direction = 0;
	var checking_precission = 45;
	var check_x = 1;
	var check_y = 0;
	var checking_distance = 1;
	var current_iter = 0;
	
	// While our current position is stuck in a wall
	while (CheckGround(check_x, check_y) && current_iter<300) {
		// Check in a circle which is the closest free position
		// If there is no free position in the circle increase the circle radius
		checking_direction = (checking_direction+checking_precission)%360;
		checking_distance++;
		current_iter++;
	
		// Calculate the new checking positions
		check_x = lengthdir_x(checking_distance, checking_direction);
		check_y = lengthdir_y(checking_distance, checking_direction);
	}

	x += check_x;
	y += check_y;
}

if (mouse_check_button_pressed(mb_left)) {
	x = mouse_x;
	y = mouse_y;
}
