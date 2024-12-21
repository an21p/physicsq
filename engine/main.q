system "l physics.q";
system "p 5001";

.z.ws:{
	message:.j.k x;
	action: `$message`action;
	params: message`params;	
	// show raze "running " ,string(action);

	if[action~`loadPage; 
		`state set initState[];
		`time set .z.t;
		`input set (0f;0f);
		sub[`getState;enlist `];
		// system "t 30";
		system "t 10";
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
	: .physics.addRandomElements[state; 20]};

getState:{`func`result!(`getState; get `state)};

/*subscribe to something */
sub:{`subs upsert(.z.w;x;enlist y)};

/*publish data according to subs table */
pub:{ 
	row:(0!subs)[x]; 
	(neg row[`handle]) .j.j (value row[`func])[row[`params]]
 };

/* trigger refresh every 100ms */
.z.ts:{
	if [not `state~key `state; `state set initState[]];
	if [not `time~key `time; `time set .z.t];
	nextInput: 5f*.physics.normalise[value `input];
	dt: (`float$.z.t-value `time)%1000*60;
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
