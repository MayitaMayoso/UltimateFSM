
if (hspd && CheckTileCollision(x, y, layer_tilemap_get_id(layer_get_id("Ground")))) {
	birth = current_time-1;
	hspd = 0;
	grav = 0;
	vspd = 0;
	depth = 1000;
	image_angle += random_range(-10, 10);
}

vspd += grav;
x += hspd*dir;
y += vspd;

if (hspd) {
	image_angle = point_direction(xprevious, yprevious, x, y);	
} else {
	if (current_time > birth + life) {
		instance_destroy();
	}
	image_alpha =  1 - (current_time - birth) / life;
}

if ( y > room_height*2 ) instance_destroy();