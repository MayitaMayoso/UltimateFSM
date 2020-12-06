
FSM = new FiniteStateMachine();

var runState = new State("Run", spr_test);

runState.StepEvent = function() {
    var hdir = keyboard_check(vk_right) - keyboard_check(vk_left);
    var vdir = keyboard_check(vk_down) - keyboard_check(vk_up);
    
    x += hdir * 2;
    y += vdir * 2;
    
    if (FSM.millisecondsInState > 2000) FSM.Set("Walk");
};

var walkState = new State("Walk", spr_test);

walkState.StepEvent = function() {
    var hdir = keyboard_check(vk_right) - keyboard_check(vk_left);
    var vdir = keyboard_check(vk_down) - keyboard_check(vk_up);
    
    x += hdir * .5;
    y += vdir * .5;
    
    if (point_distance(0, 0, hdir, vdir) == 0) FSM.Set("Run");
};

FSM.Set("Run");