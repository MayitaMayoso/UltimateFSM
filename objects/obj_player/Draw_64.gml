FSM.DrawGUIEvent();
draw_text_transformed_color(10, 20, FSM.current.name, 2, 2, 0, c_orange, c_orange, c_orange, c_orange, 1);
for(var i=0 ; i<FSM.historySize ; i++) {
	draw_text_transformed(10, 20 + 40*(i+1), FSM.history[|i].name, 1.5, 1.5, 0);
}