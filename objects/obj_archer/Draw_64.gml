FSM.DrawGUIEvent();
draw_text_transformed_color(10, 20, FSM.current.name, 1.5, 1.5, 0, c_orange, c_orange, c_orange, c_orange, 1);
for(var i=1 ; i<=FSM.historySize ; i++) {
	draw_text_transformed(10, 20 + 40*i, FSM.history[|i-1].name, 1.5, 1.5, 0);
}