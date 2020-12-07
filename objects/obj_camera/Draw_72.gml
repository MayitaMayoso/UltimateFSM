draw_clear(c_black);

var tw = view.width * view.scale;
var th = view.height * view.scale;
draw_sprite(spr_sky, 0, view.x - tw / 2, view.y - th / 2);
draw_text(x+ 16, y, fps);