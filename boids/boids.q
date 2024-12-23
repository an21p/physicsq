\l ../engine/physics.q
\d .boids

scaleR0: 0.03;
scaleR1: 0.009;
scaleR2: 0.5;
scaleR3: 1%8;
vMax: 0.1f;

initState: {[n]
    `.physics.defaultCircleRadius set  30f;
    state: .physics.createCircles[n];
    // state: update pX:0f, pY:0f, static:1b from state where sym=`1;
    state: .physics.checkCollisions[state];
    :state};

applyRules: {[state]
    state: rule0[state];
    state: rule1[state];
    state: rule2[state];
    state: rule3[state];
    :state};


//// Rule 0: Tendancy to zero
rule0: {[state]
    scale: value `.boids.scaleR0;
    state: update 
                vX:vX+ scale*( 0-pX ), 
                vY:vY+ scale*( 0-pY ) 
           from state where static=0b;
    :state};


//  Rule 1: Boids try to fly towards the centre of mass of neighbouring boids. 
rule1: {[state]
    scale: value `.boids.scaleR1;
    state: update 
                vX:vX+ scale * pX-( (sum[pX]-pX)%(count[pX]-1) ), 
                vY:vY+ scale * pY-( (sum[pY]-pY)%(count[pY]-1) ) 
           from state where static=0b;
    :state};

// Rule 2: Boids try to keep a small distance away from other objects (including other boids). 
rule2: {[state]
    scale: value `.boids.scaleR2;
    ti: select sym, posi: enlist'[pX;pY], sti:static from state;
    tj: `symj xkey select symj:sym, posj: enlist'[pX;pY], stj:static from state;
    crss: select from 0!(ti cross tj) where sti=0b, not sym=symj;
    crss: update v: *'[ -1f*scale*(posi-posj) ;100f>.physics.magnitute'[posi-posj]] from crss;
    crss: 0!select v:sum[v] by sym from crss;
    crss: `sym xkey select sym, vX:@'[v;0], vY:@'[v;1]  from crss;
    state: state pj crss;
    :state};

// Rule 3: Boids try to match velocity with near boids. 
rule3: {[state]
    scale: value `.boids.scaleR3;
    state: update 
                vX:vX+ scale * vX-( (sum[vX]-vX)%(count[vX]-1) ), 
                vY:vY+ scale * vY-( (sum[vY]-vY)%(count[vY]-1) ) 
           from state where static=0b;
    :state};

// Rule 4: Limiting the speed.
rule3: {[state]
    vlim: value `.boids.vMax;
    t: select sym, v: enlist'[vX;vY], mag:.physics.magnitute'[ enlist'[vX;vY] ] from state where static=0b;
    t: update sym, v: vlim*v%mag from t;
    t: `sym xkey select sym, vX:@'[v;0], vY:@'[v;1]  from t;
    state: state pj t;
    :state};

// update functions
updateState: {[dict] 
    state: dict`state;
    dt: dict`dt;

    //// apply rules and add new velocity to state
    state: .boids.applyRules[state];

    //// apply physics using the velocities above
    state: .physics.checkCollisions[state];
    state: .physics.updatePositionsAndVelocities[state;dt]; 
    


    :state};