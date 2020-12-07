// Follow the player
view.x = lerp(view.x, obj_player.x, 0.1);
view.y = lerp(view.y, obj_player.y - 20, 0.1);

// Update the structs of port and view
port.Update();
view.Update(port);