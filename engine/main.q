system "l physics.q";
system "p 5001";

.z.ws:{
	message:.j.k x;
	action: `$message`action;
	
	if[action~`loadPage; 
		show raze "running " ,string(action);
		`state set initState[];
		sub[`getState;enlist `];
 	];

	// (neg[x]) .j.j message;
	// value x
	};
.z.wc: {delete from `subs where handle=x};

/* subs table to keep track of current subscriptions */
subs:2!flip `handle`func`params!"is*"$\:();

initState:{ 
	state: .physics.initWithPlane[]; 
	: .physics.addRandomElements[state; 10]};

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
	`state set .physics.updateState[state];
	pub each til count subs;
	};

system "t 30";
