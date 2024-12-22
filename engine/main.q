system "l physics.q";
system "p 5001";

`objCount set 150;
`inputScale set 20f;

.z.ws:{
	message:.j.k x;
	action: `$message`action;
	params: message`params;	
	// show raze "running " ,string(action);

	if[action~`loadPage; 
		`state set initState[];
		`time set .z.t;
		`input set (0f;0f);
		`.physics.restitution set 0.9f;
		sub[`getState;enlist `];
		// system "t 30";
		system "t 1";
 	];

	// if[action~`move; 
	// 	// show message`params;
	// 	`input set message`params;
	// 	// show input;
 	// ];

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
.z.wc: {delete from `subs where handle=x};

/* subs table to keep track of current subscriptions */
subs:2!flip `handle`func`params!"is*"$\:();

initState:{ 
	state: .physics.initState[]; 
	state: .physics.addBox[state]; 
	: .physics.addRandomElements[state; value `objCount]};

getState:{`func`result!(`getState; get `state)};

/*subscribe to something */
sub:{`subs upsert(.z.w;x;enlist y)};

/*publish data according to subs table */
pub:{ 
	row:(0!subs)[x]; 
	(neg row[`handle]) .j.j (value row[`func])[row[`params]]
 };

// runs every 1 millisecond
.z.ts:{
	if [not `state~key `state; `state set initState[]];
	if [not `time~key `time; `time set .z.t];
	nextInput: (value `inputScale)*.physics.normalise[value `input];
	now: .z.t;
	dt: (`float$now-value `time)%1000; // turn milliseconds into seconds (for the simulations)
	`time set now;
	show  "dt:",string dt;
	dict: (`state`input`dt)!(value `state;nextInput;dt);
	nextState: .Q.trp[.physics.updateState;dict;{2"error: ",x,"\nbacktrace:\n",.Q.sbt [y];value `state}];
	`state set nextState;
	if [not all 0 = value `input; `input set (0f;0f);];
	pub each til count subs;
	};

debug: {
	`input set (0f;0f);
	st: initState[];
	show st;
	st: .physics.updateState[st;input];
	st: .physics.updateState[stop;input]}
