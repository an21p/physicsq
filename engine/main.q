\l physics.q
\p 5001

`objCount set 20;
`inputScale set 200f;
`.physics.restitution set 0.9f;

.z.ws:{.Q.trp[runWS;x;{2"error: ",x,"\nbacktrace:\n",.Q.sbt [y];value `state}]};

runWS:{
	message:.j.k x;
	action: `$message`action;
	// params: message`params;	
	// show raze "running " ,string(action);

	if[action~`loadPage; 
		`state set initState[];
		`input set (0f;0f);
		// sub[`getState;enlist `];
		(neg .z.w) .j.j getState[];
 	];

	if[action~`update;
		// direction: `$message`params;
		delta: `float$message`delta;
		show  "dt:",string delta;
		
		nextInput: (value `inputScale)*.physics.normalise[value `input];
		dict: (`state`input`dt)!(value `state;nextInput;delta);
		`state set .physics.updateState[dict];
		
		if [not all 0 = value `input; `input set (0f;0f)];
		(neg .z.w) .j.j getState[];
	]; 

	if[action~`move; 
		direction: `$message`params;
		input: value `input;
		m: (0f; 0f);

		//show direction;

		if [direction~`up;
			m: (0f; 1f);
		];
		if [direction~`down;
			m: (0f; -1f);
		];
		if [direction~`right;
			m: (1f; 0f);
		];
		if [direction~`left;
			m: (-1f; 0f);
		];

		`input set input+m;
 	];

	};

initState:{ 
	state: .physics.initState[]; 
	state: .physics.addBox[state]; 
	: .physics.addRandomElements[state; value `objCount]};

getState:{`func`result!(`getState; get `state)};