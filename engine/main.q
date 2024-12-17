system "l physics.q";
system "p 5001";

.z.ws:{
	message:.j.k x;
	action: `$message`action;
	params: message`params;	
	show raze "running " ,string(action);

	if[action~`loadPage; 
		`state set initState[];
		`input set (`x`y`z)!0f,0f,0f;
		sub[`getState;enlist `];
		system "t 1";
 	];

	if[action~`move; 
		// show message`params;
		`input set message`params;
		// show input;
 	];
	};
.z.wc: {delete from `subs where handle=x};

/* subs table to keep track of current subscriptions */
subs:2!flip `handle`func`params!"is*"$\:();

initState:{ 
	state: .physics.initWithPlane[]; 
	: .physics.addRandomElements[state; 2]};

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
	if [not `state~key `state ; `state set .physics.initState[]];
	`state set .physics.updateState[state; value `input];
	`input set (`x`y`z)!0f,0f,0f;
	pub each til count subs;
	};


debug: {
	`input set (`x`y`z)!0f,0f,0f;
	st: initState[];
	show st;
	st: .physics.updateState[st;input];
	st: .physics.updateState[stop;input]}
