/// @function  Print(message [, message]);
/// @description Prints on the console every parameter given to the function.
/// @parameter [ Message ]
function Print(messsage) {
	if ( argument_count == 1 ) show_debug_message(messsage);
	else {
		var totalMessage = "";
		for ( var i=0; i < argument_count - 1 ; i++ ) totalMessage += string(argument[i]) + " ";
		totalMessage += string(argument[argument_count - 1]);
			
		show_debug_message(totalMessage);
	}
};

/// @function DefaultValue(variable, defaultValue)
/// @description Sets the given variable to the default value if it is undefined.
/// @parameter variable
/// @parameter defaultValue
function DefaultValue(variable, defaultValue) {
	return ( variable == undefined ) ? defaultValue : variable;
};

/// @function IsIn(value, list)
/// @description Checks if the given list contains the value.
/// @parameter value
/// @parameter {Array} list
function IsIn(value, list) {	
	for( var i=0 ; i<array_length(list) ; i++ ) {
		if ( list[i] == value ) return true;
	}
	
	return false;
};

/// @function Within(value, minimum, maximum)
/// @description Checks if the given value is between the min and the max.
/// @parameter {Real} value
/// @parameter {Real} minimum
/// @parameter {Real} maximum
function Within(value, minimum, maximum) {	
	if ( minimum < maximum )
		return value >= minimum && value <= maximum;
	else
		return value <= minimum && value >= maximum;
};

/// @function approach(from, to, amount)
/// @description Approach by a constant the given amount in the direction of the target value.
/// @parameter {Real} from
/// @parameter {Real} to
/// @parameter {Real} amount
function Approach(from, to, amount) {
	if(from < to){
		return min(from + amount, to); 
	}else{
		return max(from - amount, to);
	}
};

/// @function Wave(from, to, period, offset)
/// @description Gives an oscilated value between two numbers in the given amount of milisecons.
/// @parameter {Real} from
/// @parameter {Real} to
/// @parameter {Real} period
/// @parameter [ {Real} offset ]
function Wave(from, to, period, offset) {
	offset = DefaultValue(offset, 0);
	var amplitude = ( to - from ) / 2;
	return from + amplitude + amplitude * sin( 2 * pi * current_time / period + offset * period );
};

/// @function Wrap(value, minimum, maximum)
/// @description If the given value surpases one of the boundaries it appears by the other side.
/// @parameter {Real} value
/// @parameter {Real} minimum
/// @parameter {Real} maximum
function Wrap(value, minimum, maximum) {
	var range = maximum - minimum;
	while(value >= maximum) value -= range;
	while(value < minimum) value += range;
	return value;
};