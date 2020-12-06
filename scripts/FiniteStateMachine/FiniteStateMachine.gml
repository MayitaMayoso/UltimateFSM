#region FINITE STATE MACHINE
	#macro FSM_HISTORY_MAX 10

	function FiniteStateMachine() constructor {
		self.instance = other;
		self.states = ds_list_create();
		self.statesSize = 0;
		
		self.current = -1;
		self.next = -1;
		self.history = ds_list_create();
		self.historySize = 0;
		
		self.framesInState = 0;
		self.millisecondsInState = 0;
		self.timeOnStateBegin = current_time;
		
		#region FSM EVENTS
		
			// Call this method on the Step Begin Event of your instance
			function StepBeginEvent() {
				if ( !self.statesSize ) return;
				// If a new state is selected
				if ( self.next != -1 ) {
					// Set the new state and call its State Begin Event
					self.current = self.next;
					self.next = -1;
					
					if (is_method(self.current.StateBeginEvent))
						self.current.StateBeginEvent();
					
					// Reset the timers
					self.framesInState = 0;
					self.millisecondsInState = 0;
					self.timeOnStateBegin = current_time;
				} else {
					// Update the timers
					self.framesInState++;
					self.millisecondsInState = current_time - self.timeOnStateBegin;
				}
				
				if (is_method(self.current.StepBeginEvent))
					self.current.StepBeginEvent();
			};
			
			// Call this method on the Step Event of your instance
			function StepEvent() {
				if ( !self.statesSize ) return;
				
					self.current.StepEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function StepEndEvent() {
				if ( !self.statesSize ) return;
				
				if (is_method(self.current.StepEndEvent))
					self.current.StepEndEvent();
					
				if ( self.next != -1 ) {
					if (is_method(self.current.StateEndEvent))
						self.current.StateEndEvent();
				}
			};
			
			// Call this method on the Step End Event of your instance
			function DrawBeginEvent() {
				if ( !self.statesSize ) return;
				self.current.DrawBeginEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function DrawEvent() {
				if ( !self.statesSize ) return;
				var inst = self.instance;
				draw_sprite_ext(
								self.current.sprite, self.framesInState,
								inst.x, inst.y, inst.image_xscale, inst.image_yscale,
								inst.image_angle, inst.image_blend, inst.image_alpha
								);
				self.current.DrawEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function DrawEndEvent() {
				if ( !self.statesSize ) return;
				self.current.DrawEndEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function DrawGUIBeginEvent() {
				if ( !self.statesSize ) return;
				self.current.DrawGUIBeginEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function DrawGUIEvent() {
				if ( !self.statesSize ) return;
				self.current.DrawGUIEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function DrawGUIEndEvent() {
				if ( !self.statesSize ) return;
				self.current.DrawGUIEndEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function DrawPreEvent() {
				if ( !self.statesSize ) return;
				self.current.DrawPreEvent();
			};
			
			// Call this method on the Step End Event of your instance
			function DrawPostEvent() {
				if ( !self.statesSize ) return;
				self.current.DrawPostEvent();
			};
		
		#endregion
		
		#region FSM CONFIGURATION
		
			// Add new event to the list.
			// You shall never call this function. It works automatically.
			function Register(state) {
				ds_list_add(self.states, state);
				self.statesSize++;
			};
		
			// Call this method on the cleanup event of your instance or you might get a memory leak
			function Cleanup() {
				ds_list_destroy(self.states);
				ds_list_destroy(self.history);
			};
		
			// Change the state
			function Set(state) {
				for( var i=0 ; i<self.statesSize ; i++ ) {
					if ( string_upper(self.states[|i].name) == string_upper(state) ) {
						// Update the states history. If the size of the history exceeded we will pop.
						if (self.current != -1) {
							ds_list_insert(self.history, 0, self.current);
							self.historySize++;
						}
						if ( ds_list_size(self.history) > FSM_HISTORY_MAX && FSM_HISTORY_MAX == -1 ) {
							ds_list_delete(self.history, self.historySize-1);
							self.historySize--;
						}
							
						// Store the next State so we can change on the next frame
						self.next = self.states[|i];
					}
				}
			};
			
			// Go back to the previous state
			function Previous() {
				if ( self.historySize ) {
					// Store the previous State so we can change on the next frame
					self.next = self.history[|self.historySize-1];
					
					// Update the states history
					ds_list_delete(self.history, 0);
					self.historySize--;
				}
			};
		
			// If for some reason you want to unregister a state you have this
			function Unregister(state) {
				var idx = ds_list_find_index(self.states, state);
				ds_list_delete(self.states, idx);
				self.statesSize--;
			};
		
		#endregion
	};

#endregion

#region STATE

	function State(name, sprite) constructor {
		self.instance = other;
		self.fsm = self.instance.FSM;
		self.name = name;
		self.fsm.Register(self);
		self.sprite = DefaultValue(sprite, -1);
		
		self.StateBeginEvent = function() {};
		self.StateEndEvent = function() {};
		self.StepBeginEvent = function() {};
		self.StepEvent = function() {};
		self.StepEndEvent = function() {};
		self.DrawBeginEvent = function() {};
		self.DrawEvent = function() {};
		self.DrawEndEvent = function() {};
		self.DrawGUIBeginEvent = function() {};
		self.DrawGUIEvent = function() {};
		self.DrawGUIEndEvent = function() {};
		self.DrawPreEvent = function() {};
		self.DrawPostEvent = function() {};
	};

#endregion