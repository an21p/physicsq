\l boids.q
\p 5002
\c 100 115

`objCount set 300;
`.physics.gravity set 0f;
`.physics.restitution set 0.5f;

.z.ws:{.Q.trp[runWS;x;{2"error: ",x,"\nbacktrace:\n",.Q.sbt [y];value `state}]};

runWS: {
	// show x;
	message:.j.k x;
	action: `$message`action;
	// params: message`params;	
	// show raze "running " ,string(action);

	if[action~`mouse; 
		`.boids.targetX set `float$message`x;
		`.boids.targetY set `float$message`y;
 	];

	if[action~`settings; 

		k: `$message`key;
		v: `float$message`value;

		if[`ruleZeroScale ~ k; `.boids.scaleR0 set v];
		if[`ruleOneScale ~ k; `.boids.scaleR1 set v];
		if[`ruleTwoScale ~ k; `.boids.scaleR2 set v];
		if[`ruleTwoDisance ~ k; `.boids.distance set v];
		if[`ruleThreeScale ~ k; `.boids.scaleR3 set v];
		if[`maxSpeed ~ k; `.boids.vMax set v];
 	];

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