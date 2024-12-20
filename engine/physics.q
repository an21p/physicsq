system "d .physics"

PI:3.141592653589793238;
gravity: 0f; // -0.981f;

initState: {[] flip `sym`shape`invM`pX`pY`vX`vY`fX`fY`rX`rY`sX`sY`static!"ssfffffffffffb"$\:()};

getPositionVector: {[a] :a`pX`pY };
getVelocityVector: {[a] :a`vX`vY };
getForceVector:    {[a] :a`fX`fY };
getRotationVector: {[a] :a`rX`rY };
getSizeVector:     {[a] :a`sX`sY };

initWithPlane: { 
    state: initState[];  
    state: addPlane[state];  
    :state};

addPlane: {[state] :state upsert (`planeX;`plane;1%100f;0f;0f;0f;0f;0f;0f;0f;0f;1000f;1f;1b)};
addBox: {[state] 
    state: state upsert (`planeT;`plane;1%100f;   0f; 500f;0f;0f;0f;0f;0f;0f;1200f;  10f;1b);
    state: state upsert (`planeR;`plane;1%100f; 600f;   0f;0f;0f;0f;0f;0f;0f;  10f;1024f;1b);
    state: state upsert (`planeB;`plane;1%100f;   0f;-500f;0f;0f;0f;0f;0f;0f;1200f;  10f;1b);
    state: state upsert (`planeL;`plane;1%100f;-600f;   0f;0f;0f;0f;0f;0f;0f;  10f;1024f;1b);
    :state};

/ add x random elemenents to state
addRandomElements: {[state; x]
    r: 15;
    shperes: ([] sym: (`$ string each til x);   // unique id
                    shape: x#`sphere;               
                    invM: 1%x#10;              // inverse mass up to 3
                    pX: -400+x?800;
                    pY: -400+x?800;
                    vX: x#0; vY: x#0;
                    fX: x#0; fY: x#0;
                    rX: x#0; rY: x#0;
                    sX: x#r; sY: x#r;
                    static: 0b);
    r: 25;
    rectangles: ([] sym: (`$ string each x+til x);   // unique id
                    shape: x#`plane;               
                    invM: 1%x#10;              // inverse mass up to 3
                    pX: -400+x?800;
                    pY: -400+x?800;
                    vX: x#0; vY: x#0;
                    fX: x#0; fY: x#0; 
                    rX: x#0; rY: x#0;
                    sX: x#r; sY: x#r;
                    static: 0b);
    state: state uj rectangles uj shperes;
    :state};

/ return the current state
getState: {[state] select sym,shape,pX,pY,rX,rY,sX,sY from state };

acceleration: {[force; invMass] :force*invMass};

updatePositionsAndVelocities: {[state; dt]
    / 1. Update velocity for X, Y components    
    state: update vX:vX+dt*.physics.acceleration[fX;invM], 
                  vY:vY+dt*.physics.acceleration[.physics.gravity+fY;invM]
            from state where static = 0b;
    / 2. Update position for X, Y components 
    state: update pX:pX+vX, pY:pY+vY from state;

    / 3. Update angular velocity for X, Y components 
    / 4. Update rotation for X, Y, Z components (mod by 2π)
            // float angularAcceleration = rigidBody->torque / rigidBody->shape.momentOfInertia;
            // rigidBody->angularVelocity += angularAcceleration * dt;
            // rigidBody->angle += rigidBody->angularVelocity * dt;
    :state};



updatePositionsAndVelocitiesWithInput: {[state; input; dt]
    // show "xx",input;
    invM: first value first select invM from state where sym=`1;
    acc: .physics.acceleration[input;invM];
    aX: (acc 0);
    aY: (acc 1);

    / 1. Update velocity for X, Y components 
    state: update vX:vX+dt*aX, vY:vY+dt*aY from state where sym = `1;   
    / 2. Update position for X, Y components 
    state: update pX:pX+dt*vX, pY:pY+dt*vY from state where sym = `1;   
    :state};


/ Calculate AABB for all objects
calculateAABB:{[state] 
    // spheres
    state: update minX:pX-sX, maxX:pX+sX, minY:pY-sY, maxY:pY+sY from state;
    :state};


// Normalise vector to magnitute 1
// @param v vector
// @return normalised vector
normalise: {[v] :0^v%sqrt sum v*v}
distanceSpheres: {[a;b] :sqrt sum v*v: getPositionVector[a]-getPositionVector[b]}

/ Sort and Sweep collision detection
sortAndSweepCollision:{[state]
  / 1. Calculate AABB for all objects
  / state: .physics.convertToBodyCoordinates[state];
  stateWithAABB: calculateAABB[state];

  / 2. Sort by minX
  stateWithAABB: `minX xasc stateWithAABB;

  / 3. Sweep through and check overlaps
  overlappingPairs:([] 
    a:`symbol$(); 
    b:`symbol$();
    aShape:`symbol$(); 
    bShape:`symbol$());
  n: count stateWithAABB;

  i:0;
  while [i<n; 

        //show  `$string "i",i;
        a: stateWithAABB i;
        j:i+1;
        while [j<n;
           // show  `$string "j",j;
            b: stateWithAABB j;

            bothStatic: 0b;
            if [and[1b~a`static;1b~b`static];bothStatic:1b];

            if[ (b`minX) < a`maxX;
                (a`maxY) > b`minY;
                (a`minY) < b`maxY;
                bothStatic ~ 0b;
                overlappingPairs: overlappingPairs upsert (a`sym;b`sym;a`shape;b`shape);
            ];
            j+:1;

        ];
        i+:1;
    ];
  :overlappingPairs
  };

intersectSpheres: {[pair]
    // show "intersectSpheres";

    result: ([] 
        sym: `symbol$(); 
        pXn: `float$(); 
        pYn: `float$(); 
        vXn: `float$(); 
        vYn: `float$());
    // if [0~ count pair; :result];

    a:pair 0;
    b:pair 1;

    dist: distanceSpheres[a;b];
    redi: (a`sX) + b`sX;

    if[dist >= redi; :result];

    centerA: getPositionVector[a];
    centerB: getPositionVector[b];

    normal: normalise[centerB - centerA]; // vector pointing from A to B (to push B out of the way)
    depth: redi-dist;
    
    impulse: calculateImpulse[a;b;normal];

    if [1b~a`static;
        moveB: normal * depth;
        velB: impulse * b`invM];

    if [1b~b`static;
        moveA: -1 * normal * depth;
        velA: -1 * impulse * a`invM];

    if [0b~a`static;
        0b~b`static;
        moveB: normal * depth%2;
        moveA: -1 * moveB;
        velA: -1 * impulse * a`invM;
        velB: impulse * b`invM];

    result: result upsert ((a`sym);(moveA 0);(moveA 1); (velA 0);(velA 1));
    result: result upsert ((b`sym);(moveB 0);(moveB 1); (velB 0);(velB 1));
    :result}


calculateImpulse: {[a;b;normal] 
    resitution: 0.1f; 
    relativeVelocity: getVelocityVector[b]-getVelocityVector[a];
    j: -1*(1f+resitution) * (relativeVelocity mmu normal);
    :normal *j % (a`invM)+b`invM};

resolveCollisions: {[state; pairs]
  //show "resolveCollisions";

  collidingSpheres: select from pairs where aShape = `sphere, bShape = `sphere;
  n: count collidingSpheres;

    i:0;
    while [i<n;
        x: collidingSpheres i;
        k: (x`a),x`b;
        pair: select from state where sym in k;
        transformations: intersectSpheres[pair];
  
        if [not 0~ count transformations;
            // show transformations;
            tmpState: state lj `sym xkey transformations;
            //show transformations;
            // adjust position in case of intersection
            tmpState: delete pXn,pYn from update pX:pX+pXn, pY:pY+pYn from tmpState where not pXn=0n;
            // apply new velocity
            state: delete vXn,vYn from update vX:vX+vXn, vY:vY+vYn from tmpState where not vXn=0n;
        ];
        i+:1;
    ];



  :state};

checkCollisions: {[state] 
    pairs: sortAndSweepCollision[state];
    state: resolveCollisions[state; pairs];
    :state};

updateState: {[state; input; dt] 
    if [not all 0=input;
        state: updatePositionsAndVelocitiesWithInput[state;input;dt]; 
    ]
    state: updatePositionsAndVelocities[state;dt]; 
    state: checkCollisions[state];
    :state};
