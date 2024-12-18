system "d .physics"

PI:3.141592653589793238;
gravity: 0f; // -0.981f;

initState: {[] flip `sym`shape`m`pX`pY`pZ`vX`vY`vZ`fX`fY`fZ`rX`rY`rZ`sX`sY`sZ`static!"ssffffffffffffffffb"$\:()};

initWithPlane: { 
    state: initState[];  
    state: addPlane[state];  
    :state};

addPlane: {[state] :state upsert (`planeX;`plane;1f;0f;0f;0f;0f;0f;0f;0f;0f;0f;-1*.physics.PI%2;0f;0f;1000f;1000f;1f;1b)};

/ add x random elemenents to state
addRandomElements: {[state; x]
    r: 15;
    elements: ([] sym: (`$ string each til x);   // unique id
                    shape: x#`sphere;               
                    m: x?1+til 3;                // mass up to 3
                    pX: -400+x?800;
                    pY: 30; //20+x?100;
                    pZ: x#0; 
                    vX: x#0; vY: x#0; vZ: x#0;
                    fX: x#0; fY: x#0; fZ: x#0;
                    rX: x#0; rY: x#0; rZ: x#0;
                    sX: x#r; sY: x#r; sZ: x#r;
                    static: 0b);
    state: state uj elements;
    :state};

/ return the current state
getState: {[state] select sym,shape,pX,pY,pZ,rX,rY,rZ,sX,sY,sZ from state };

applyForces: {[state] :state};

acceleration: {[force; mass] acc:force%mass; acc[where abs[acc]=0w]:0n; :0^acc };

updatePositionsAndVelocities: {[state]
    / 1. Update velocity for X, Y, Z components 
    state: update vX:vX+.physics.acceleration[fX;m], 
                  vY:vY+.physics.acceleration[.physics.gravity+fY;m], 
                  vZ:vZ+.physics.acceleration[fZ;m]
            from state where static = 0b;
    / 2. Update position for X, Y, Z components 
    state: update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from state;
    :state};

    / 3. Update angular velocity for X, Y, Z components 
    / 4. Update rotation for X, Y, Z components (mod by 2π)
            // float angularAcceleration = rigidBody->torque / rigidBody->shape.momentOfInertia;
            // rigidBody->angularVelocity += angularAcceleration * dt;
            // rigidBody->angle += rigidBody->angularVelocity * dt;

updatePositionsAndVelocitiesWithInput: {[state; input]
    // show "xx",input;
    m1: first value first select m from state where sym=`1;
    acc: .physics.acceleration[input;m1];
    aX: (acc 0);
    aY: (acc 1);
    aZ: (acc 2);

    / 1. Update velocity for X, Y, Z components 
    state: update vX:vX+aX, vY:vY+aY, vZ:vZ+aZ from state where sym = `1;   
    / 2. Update position for X, Y, Z components 
    state: update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from state where sym = `1;   
    // state: update pX:pX+dX, pY:pY+dY, pZ:pZ+dZ from state where sym = `1;
    :state};

/ Calculate AABB for all objects
calculateAABB:{[state] :update minX:pX-sX, maxX:pX+sX, minY:pY-sY, maxY:pY+sY, minZ:pZ-sZ, maxZ:pZ+sZ from state };

// Normalise vector to magnitute 1
// @param v vector
// @return normalised vector
normalise: {[v] :0^v%sqrt sum v*v}

// Convert a row from state into a vector
// @param s a row from state
// @return vector
getSphereCenter: {[s] :(s`pX; s`pY; s`pZ)}

distanceSpheres: {[a;b] :sqrt sum v*v: getSphereCenter[a]-getSphereCenter[b]}

intersectSpheres: {[pair]
    // show "intersectSpheres";

    result: ([] sym: `symbol$(); pXn: `float$(); pYn: `float$(); pZn: `float$());
    // if [0~ count pair; :result];

    a:pair 0;
    b:pair 1;

    dist: distanceSpheres[a;b];
    redi: (a`sX) + b`sX;

    if[dist >= redi; :result];

    centerA: getSphereCenter[a];
    centerB: getSphereCenter[b];

    normal: normalise[centerB - centerA]; // vector pointing from A to B (to push B out of the way)
    depth: redi-dist;

    moveB: normal * depth%2;
    moveA: -1 * moveB;

    result: result upsert ((a`sym);(moveA 0);(moveA 1);(moveA 2));
    result: result upsert ((b`sym);(moveB 0);(moveB 1);(moveB 2));
    :result}

/ Sort and Sweep collision detection
sortAndSweepCollision:{[state]
  / 1. Calculate AABB for all objects
  / state: .physics.convertToBodyCoordinates[state];
  stateWithAABB: calculateAABB[state];

  / 2. Sort by minX
  stateWithAABB: `minX xasc stateWithAABB;

  / 3. Sweep through and check overlaps
  overlappingPairs:([] a:`symbol$(); b:`symbol$(); aShape:`symbol$(); bShape:`symbol$());
  n: count stateWithAABB;

  i:0;
  while [i<n; 
        // show  `$string "i",i;
        a: stateWithAABB i;
        j:i+1;
        while [j<n;
            // show  `$string "j",j;
            b: stateWithAABB j;
            if[(b`minX) < a`maxX;
            (a`maxY) > b`minY;
            (a`minY) < b`maxY;
            (a`maxZ) > b`minZ;
            (a`minZ) < b`maxZ;
            overlappingPairs: overlappingPairs upsert (a`sym;b`sym;a`shape;b`shape);
            ];
            j+:1;
        ];
        i+:1;
    ];

  :overlappingPairs
  };

checkCollisionsNarrow: {[state; pairs]
  //show "checkCollisionsNarrow";

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
            state: state lj `sym xkey transformations;
            state: delete pXn,pYn,pZn from update pX:pX+pXn, pY:pY+pYn, pZ:pZ+pZn from state where not pXn=0n
        ];
        i+:1;
    ];



  :state};

checkCollisions: {[state] 
    pairs: sortAndSweepCollision[state];
    state: checkCollisionsNarrow[state; pairs];
    :state};

updateState: {[state; input] 
    state: applyForces[state]; 
    if [not all 0=input;
        state: updatePositionsAndVelocitiesWithInput[state;input]; 
    ]
    state: updatePositionsAndVelocities[state]; 
    state: checkCollisions[state];
    :state};
