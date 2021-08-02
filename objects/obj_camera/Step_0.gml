// Follow the player
view.x = lerp(view.x, obj_archer.x, 0.1);
view.y = lerp(view.y, obj_archer.y - 20, 0.1);

// Update the structs of port and view
port.Update();
view.Update(port);