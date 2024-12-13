\l physics.q
\p 5001 
.z.ws:{
	message:.j.k x;
	action: `$message`action;
	
	if[action~`loadPage; 
		show raze "running " ,string(action);
		sub[`getState;enlist `]
 	];

	// (neg[x]) .j.j message;
	// value x
	};
.z.wc: {delete from `subs where handle=x};

/* subs table to keep track of current subscriptions */
subs:2!flip `handle`func`params!"is*"$\:();

getState:{ 
	// show raze "state";
	res: .physics.getState[];
	show res;
	`func`result!(`getState;res)
	};

/*subscribe to something */
sub:{`subs upsert(.z.w;x;enlist y)};

/*publish data according to subs table */
pub:{ 
	row:(0!subs)[x]; 
	(neg row[`handle]) .j.j (value row[`func])[row[`params]]
 };



/* trigger refresh every 100ms */
.z.ts:{
	.physics.updateState[];
	pub each til count subs;
	};
\t 100
