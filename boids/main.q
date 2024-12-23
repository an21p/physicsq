\l boids.q
\p 5002
\c 100 115

`objCount set 250;
`.physics.gravity set 0f;
`.physics.restitution set 0.5f;

.z.ws:{.Q.trp[runWS;x;{2"error: ",x,"\nbacktrace:\n",.Q.sbt [y];value `state}]};

runWS: {
	message:.j.k x;
	action: `$message`action;
	// params: message`params;	
	// show raze "running " ,string(action);

	if[action~`loadPage; 
		`state set .boids.initState[value `objCount];
		(neg .z.w) .j.j getState[];
 	];

	if[action~`update;
		delta: `float$message`delta;
		// show  "dt:",string delta;
		dict: (`state`dt)!(value `state;delta);
		`state set .boids.updateState[dict];
		(neg .z.w) .j.j getState[];
	]};

getState:{`func`result!(`getState; get `state)};