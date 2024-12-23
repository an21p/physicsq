\l ../engine/physics.q
\d .boids

scaleRM: 0.025;
scaleR0: 0.025;
scaleR1: 0.018;
scaleR2: 0.1;
distance: 100f;
scaleR3: 0.125;
vMax: 95f;
targetX: 0f;
targetY: 0f;

initState: {[n]
    `.physics.defaultCircleRadius set  50f;
    state: .physics.createCircles[n];
    // state: update pX:0f, pY:0f, static:1b from state where sym=`1;
    state: .physics.checkCollisions[state];
    :state};

//// Rule M: Tendancy to mouse
ruleM: {[state]
    scale: value `.boids.scaleRM;
    :`sym xkey select sym, 
                vX:scale*( (value `.boids.targetX)-pX ), 
                vY:scale*( (value `.boids.targetY)-pY ) 
           from state where static=0b};

//// Rule 0: Tendancy to zero
rule0: {[state]
    scale: value `.boids.scaleR0;
    :`sym xkey select sym, 
                vX:scale* ( 0-pX ), 
                vY:scale* ( 0-pY ) 
           from state where static=0b};


//  Rule 1: Boids try to fly towards the centre of mass of neighbouring boids. 
rule1: {[state]
    scale: value `.boids.scaleR1;
    :`sym xkey select sym, 
                vX:scale * pX-( (sum[pX]-pX)%(count[pX]-1) ), 
                vY:scale * pY-( (sum[pY]-pY)%(count[pY]-1) ) 
           from state where static=0b};

// Rule 2: Boids try to keep a small distance away from other objects (including other boids). 
rule2: {[state]
    scale: value `.boids.scaleR2;
    distance: value `.boids.distance;
    ti: select sym, posi: enlist'[pX;pY], sti:static from state;
    tj: `symj xkey select symj:sym, posj: enlist'[pX;pY], stj:static from state;
    crss: select from 0!(ti cross tj) where sti=0b, not sym=symj;
    crss: update v: *'[ -1f*scale*(posi-posj) ;distance>.physics.magnitute'[posi-posj]] from crss;
    crss: 0!select v:sum[v] by sym from crss;
    : `sym xkey select sym, vX:@'[v;0], vY:@'[v;1]  from crss};

// Rule 3: Boids try to match velocity with near boids. 
rule3: {[state]
    scale: value `.boids.scaleR3;
    :`sym xkey select sym, 
                vX:scale * vX-( (sum[vX]-vX)%(count[vX]-1) ), 
                vY:scale * vY-( (sum[vY]-vY)%(count[vY]-1) ) 
           from state where static=0b};

// Rule *: Limiting the speed.
limitSpeed: {[state]
    vlim: value `.boids.vMax;
    t: select sym, v: enlist'[vX;vY], mag:.physics.magnitute'[ enlist'[vX;vY] ] from state where static=0b;
    t: update sym, v: vlim*v%mag from t;
    t: `sym xkey select sym, vX:@'[v;0], vY:@'[v;1]  from t;
    state: state lj t;
    :state};

applyRules: {[state]
    rM: .boids.ruleM[state];
    r0: .boids.rule0[state];
    r1: .boids.rule1[state];
    r2: .boids.rule2[state];
    r3: .boids.rule3[state];

    state: state pj rM;
    state: state pj r0;
    state: state pj r1;
    state: state pj r2;
    state: state pj r3;
    :state};

// update functions
updateState: {[dict] 
    state: dict`state;
    dt: dict`dt;

    //// apply rules and add new velocity to state
    state: .boids.applyRules[state];
    state: .boids.limitSpeed[state];

    //// apply physics using the velocities above
    // state: .physics.checkCollisions[state];
    state: .physics.updatePositionsAndVelocities[state;dt]; 
    


    :state};