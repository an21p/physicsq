system "d .physics"

PI:3.141592653589793238;
gravity: 0f; // -0.981f;

initState: {[] flip `sym`shape`invM`pX`pY`pZ`vX`vY`vZ`fX`fY`fZ`rX`rY`rZ`sX`sY`sZ`static!"ssffffffffffffffffb"$\:()};

getPositionVector: {[a] :a`pX`pY`pZ };
getVelocityVector: {[a] :a`vX`vY`vZ };
getForceVector:    {[a] :a`fX`fY`fZ };
getRotationVector: {[a] :a`rX`rY`rZ };
getSizeVector:     {[a] :a`sX`sY`sZ };

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
                    invM: 1%x?1+til 3;              // inverse mass up to 3
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

acceleration: {[force; invMass] :force*invMass};

updatePositionsAndVelocities: {[state]
    / 1. Update velocity for X, Y, Z components 
    state: update vX:vX+.physics.acceleration[fX;invM], 
                  vY:vY+.physics.acceleration[.physics.gravity+fY;invM], 
                  vZ:vZ+.physics.acceleration[fZ;invM]
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
    invM: first value first select invM from state where sym=`1;
    acc: .physics.acceleration[input;invM];
    aX: (acc 0);
    aY: (acc 1);
    aZ: (acc 2);

    / 1. Update velocity for X, Y, Z components 
    state: update vX:vX+aX, vY:vY+aY, vZ:vZ+aZ from state where sym = `1;   
    / 2. Update position for X, Y, Z components 
    state: update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from state where sym = `1;   
    :state};

/ Calculate AABB for all objects
calculateAABB:{[state] 
    // spheres
    state: update minX:pX-sX, maxX:pX+sX, minY:pY-sY, maxY:pY+sY, minZ:pZ-sZ, maxZ:pZ+sZ from state;
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
                (a`maxZ) > b`minZ;
                (a`minZ) < b`maxZ;
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
        pZn: `float$();
        vXn: `float$(); 
        vYn: `float$(); 
        vZn: `float$());
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

    result: result upsert ((a`sym);(moveA 0);(moveA 1);(moveA 2); (velA 0);(velA 1);(velA 2));
    result: result upsert ((b`sym);(moveB 0);(moveB 1);(moveB 2); (velB 0);(velB 1);(velB 2));
    :result}

calculateImpulse: {[a;b;normal] 
    resitution: 0.5f; 
    relativeVelocity: getVelocityVector[b]-getVelocityVector[a];
    j: -1*(1f+resitution) * (relativeVelocity mmu normal);
    j:j % (a`invM)+b`invM;
    j:j % normal;
    j[where abs[j]=0w]:0n; 
    :0^j};

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
            // adjust position in case of intersection
            tmpState: delete pXn,pYn,pZn from update pX:pX+pXn, pY:pY+pYn, pZ:pZ+pZn from tmpState where not pXn=0n;
            // apply new velocity
            state: delete vXn,vYn,vZn from update vX:vX+vXn, vY:vY+vYn, vZ:vZ+vZn from tmpState where not vXn=0n;
        ];
        i+:1;
    ];



  :state};

checkCollisions: {[state] 
    pairs: sortAndSweepCollision[state];
    state: resolveCollisions[state; pairs];
    :state};

updateState: {[state; input] 
    state: applyForces[state]; 
    if [not all 0=input;
        state: updatePositionsAndVelocitiesWithInput[state;input]; 
    ]
    state: updatePositionsAndVelocities[state]; 
    state: checkCollisions[state];
    :state};
