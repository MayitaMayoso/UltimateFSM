#region FINITE STATE MACHINE
	#macro FSM_HISTORY_MAX 10
	#macro DEBUG false

	function FiniteStateMachine() constructor {
		self.instance = other;
		self.states = ds_list_create();
		self.statesSize = 0;
		
		self.name = "";
		self.current = -1;
		self.next = -1;
		self.previous = -1;
		self.history = ds_list_create();
		self.historySize = 0;
		
		self.framesInState = 0;
		self.millisecondsInState = 0;
		self.timeOnStateBegin = current_time;
		
		self.image = {
			direction : 1,
			facing : 1,
			xscale : 1,
			yscale : 1,
			rotation : 0,
			alpha : 1,
			blend : c_white
		};
		
		#region FSM EVENTS
		
			// Call this method on the Step Begin Event of your instance
			function StepBeginEvent() {
				if ( !self.statesSize ) return;
				// If a new state is selected
				if ( self.next != -1 ) {
					// Set the new state and call its State Begin Event
					self.previous = self.current;
					self.current = self.next;
					self.next = -1;
					
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
				
				self.current.animation.Update();
				if (self.current.animation.started) self.current.AnimationBeginEvent();
				if (self.current.animation.finished) self.current.AnimationEndEvent();
				
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
				
				self.current.StepEndEvent();
					
				if ( self.next != -1 ) {
					self.current.StateEndEvent();
					self.name = self.next.name;
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
				if (self.current.animation.sprite != -1) {
					var spr = self.current.animation.sprite;
					if (is_array(spr)) spr = spr[min(self.direction, array_length(spr)-1)];
					draw_sprite_ext(
									spr , self.current.animation.frame,
									self.instance.x, self.instance.y,
									self.image.facing * self.instance.image_xscale * self.image.xscale,
									self.instance.image_yscale * self.image.yscale,
									self.instance.image_angle + self.image.rotation,
									merge_color(self.instance.image_blend, self.image.blend, .5),
									self.instance.image_alpha * self.image.alpha
									);
				}
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
			
			function Get(state) {
				for( var i=0 ; i<self.statesSize ; i++ )
					if ( string_upper(self.states[|i].name) == string_upper(state) ) return self.states[|i];
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
						// If we already selected a state on this frame to change reverse the change
						if (self.next != -1)
							self.Previous();
						// Update the states history. If the size of the history exceeded we will pop.
						if (self.current != -1) {
							ds_list_insert(self.history, 0, self.current);
							self.historySize++;
						}
						if ( ds_list_size(self.history) > FSM_HISTORY_MAX && FSM_HISTORY_MAX != -1 ) {
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

	function State(name) constructor {
		self.instance = other;
		self.fsm = self.instance.FSM;
		self.name = name;
		self.fsm.Register(self);
		
		self.animation = {
			sprite : -1,
			speed : 1,
			loop : true,
			frame :0,
			rawFrame : 0,
			number : 1,
			lastUpdate : current_time,
			started : false,
			finished : false,
			
			Init : function(sprite, speed, loop) {
				self.sprite = sprite;
				self.speed = DefaultValue(speed, 1);
				self.loop = DefaultValue(loop, true);
				self.number = sprite_get_number(sprite);
			},
			
			Update : function() {
				if (self.fsm.framesInState==0) {
					self.rawFrame = 0;
					self.frame = 0;
					self.lastUpdate = current_time;
					self.started = true;
					self.finished = false;
					if (DEBUG) Print("============", self.fsm.current.name);
				} else {
					var delta = current_time - self.lastUpdate;
					var msPerFrame = 1000 / (self.speed * game_get_speed(gamespeed_fps));
					var deltaFrame = delta / msPerFrame;
					
					self.rawFrame += deltaFrame;
					var prevFrame = self.frame;
					self.frame = floor(rawFrame);
					
					if (self.frame >= self.number) {
						if (self.loop) self.rawFrame = self.rawFrame % self.number;
						else self.rawFrame = min(self.frame, self.number-1);
						
						self.frame = floor(rawFrame);
					}
					
					self.started = (self.frame==0 && prevFrame!=0);
					self.finished = ( self.rawFrame + deltaFrame*1.3 >= self.number );
					
					self.lastUpdate = current_time;
					if (DEBUG) Print(self.frame, self.finished);
				}
			}
		};
		
		self.animation.fsm = self.fsm;
		
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
		self.AnimationBeginEvent = function() {};
		self.AnimationEndEvent = function() {};
	};

#endregion