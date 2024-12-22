\d .physics

// constants
PI:3.141592653589793238;
gravity: -1f; //-9.81f;
restitution: 0.65f;
defaultCircleRadius: 20f;
defaultCircleMass: 50f;
defaultBoxWidth: 40f;
defaultBoxMass: 20f;

// getters
getState: {[state] :select sym,shape,pX,pY,theta,sX,sY from state };
getPositionVector: {[a] :a`pX`pY };
getVelocityVector: {[a] :a`vX`vY };
getAccelerationVector:    {[a] :a`aX`aY };
getSizeVector:     {[a] :a`sX`sY };
emptyIntersectResult: {:([] sym: `symbol$(); pXn: `float$(); pYn: `float$(); vXn: `float$(); vYn: `float$())};

// Utils
/tab : the table to operate on
/baseCols : the columns not to unpivot
/pivotCols : the columns which you wish to unpivot
/kCol : the key name for unpivoted data
/vCol :  the value name for unpivoted data
unpivot:{[tab;baseCols;pivotCols;kCol;vCol] 
 base:?[tab;();0b;{x!x}(),baseCols];
 newCols:{[k;v;t;p] flip (k;v)!(count[t]#p;t p)}[kCol;vCol;tab] each pivotCols;
 baseCols xasc raze {[b;n] b,'n}[base] each newCols
 }

// Normalise vector to magnitute 1
// @param v vector
// @return normalised vector
normalise: {[v] :0f^v%sqrt sum v*v};

// Acceleration from foce and mass
// F=ma => a=F/m
// I store inverse of mass to avoid division 
// @param force vector
// @param invMass => inverse of mass
// @return acceleration vector
acceleration: {[force; invMass] :force*invMass};

// Rotation in 2D space
// @param v => vector
// @param theta => angle in radian
// @return transformed vector
transform: {[v;theta] R: 2 2#(cos theta; -1*sin theta; sin theta; cos theta); :R mmu v};

relativeVelocity: {[a;b] :1f*getVelocityVector[b] - getVelocityVector[a]};

// Distance between spheres
distanceR: {[a;b] :sqrt sum v*v: getPositionVector[a]-getPositionVector[b]}
distanceV: {[v1;v2] :sqrt sum v*v: v1-v2}

/ Calculate AABB for all objects
calculateAABB:{[state] 
    // rectangles
    state: update minX:pX-sX%2, maxX:pX+sX%2, minY:pY-sY%2, maxY:pY+sY%2 from state where shape=`plane;
    // spheres
    state: update minX:pX-sX, maxX:pX+sX, minY:pY-sY, maxY:pY+sY from state where shape=`sphere;
    
    :state};

generatePostCollisionTransformations: {[a;b;normal;depth]
    impulse: calculateImpulse[a;b;normal];
    result: emptyIntersectResult[];
    if [0b~b`static;
        1b~a`static;
        moveB: 1f * normal * depth;
        velB: 1f * impulse * b`invM;
        result: result upsert ((b`sym);(moveB 0);(moveB 1); (velB 0);(velB 1))];

    if [0b~a`static;
        1b~b`static;
        moveA: -1f * normal * depth;
        velA: -1f * impulse * a`invM;
        result: result upsert ((a`sym);(moveA 0);(moveA 1); (velA 0);(velA 1))];

    if [0b~a`static;
        0b~b`static;
        moveB: 1f * normal * depth%2;
        moveA: -1f * moveB;
        velA: -1f * impulse * a`invM;
        velB: 1f * impulse * b`invM;
        result: result upsert ((a`sym);(moveA 0);(moveA 1); (velA 0);(velA 1));
        result: result upsert ((b`sym);(moveB 0);(moveB 1); (velB 0);(velB 1))];

    :result};


// initialisation functions
initState: {[] flip `sym`shape`invM`pX`pY`vX`vY`aX`aY`theta`sX`sY`static!"ssffffffffffb"$\:()};
initWithPlane: { :addPlane[initState[]]};
addPlane: {[state] :state upsert (`planeX;`plane;1%100f;0f;0f;0f;0f;0f;0f;0f;1000f;1f;1b)};
addBox: {[state] 
    state: state upsert (`planeT;`plane;0f;   0f; 600f;0f;0f;0f;0f;0f;1300f;100f;1b);
    state: state upsert (`planeR;`plane;0f; 700f;   0f;0f;0f;0f;0f;0f;100f;1300f;1b);
    state: state upsert (`planeB;`plane;0f;   0f;-600f;0f;0f;0f;0f;0f;1500f;500f;1b);
    state: state upsert (`planeL;`plane;0f;-700f;   0f;0f;0f;0f;0f;0f;100f;1300f;1b);
    :state};
addRandomElements: {[state; n]
    cirlces: createCircles[n];
    boxes: createBoxes[n];
    state: state uj cirlces uj boxes;
    :state};

createCircles: {
    r: defaultCircleRadius;
    circles: ([] sym: (`$ string each til x);   // unique id
                    shape: x#`sphere;               
                    invM: 1% x#defaultCircleMass;              // inverse mass
                    pX: -400+x?800f;
                    pY: -300+x?800f;
                    vX: x#0f; vY: x#0f;
                    aX: x#0f; aY: x#0f;
                    theta: x#0f;
                    sX: x#r; sY: x#r;
                    static: 0b);
    :circles}

createBoxes: {
    r: defaultBoxWidth;
    boxes: ([] sym: (`$ string each x+til x);   // unique id
                    shape: x#`plane;               
                    invM: 1% x#defaultBoxMass;              // inverse mass
                    pX: -400+x?800f;
                    pY: -300+x?800f;
                    vX: x#0f; vY: x#0f;
                    aX: x#0f; aY: x#0f; 
                    theta: x#0f;
                    sX: x#r; sY: x#r;
                    static: 0b);
    :boxes}


// Collision Resolution Functions
checkCollisions: {[state] 
    pairs: sortAndSweepCollision[state];
    state: resolveCollisions[state; pairs];
    :state};

calculateImpulse: {[a;b;normal] 
    resitution: value `.physics.restitution; 
    j: -1*(1f+resitution) * (relativeVelocity[a;b] mmu normal);
    :normal*j % (a`invM)+b`invM};


intersectBoxCircle: {[pair] 
    // Separating Axis Theorem (SAT)
    pair: update left: pX+sX%-2, bottom: pY+sY%-2 from pair;
    pair: update right: sX+left, top: sY+bottom from pair;
    pair: update LT: enlist'[left;top],
                 TR: enlist'[right;top], 
                 RB: enlist'[right;bottom], 
                 BL: enlist'[left;bottom] 
                from pair where shape=`plane;

    vertices: unpivot[select sym,LT,TR,RB,BL from pair where shape=`plane;`sym;`LT`TR`RB`BL;`vertex;`vector ];

    a:pair 0; // box
    b:pair 1; // circle
    centerB: getPositionVector[b];


    depth: 0w;
    normal: 0n;

    n: count vtx: `LT`TR`RB`BL;

    //check projections on vertices of a
    i:0;
    while[i<n;
        v1: a[ vtx i ];
        v2: a[ vtx (1+i) mod n ];
        edge: v2 - v1;
        axis: normalise[(-1*edge 1; edge 0)];
        vertices: update projection: vector mmu axis from vertices;
        m: select minP:min projection, maxP:max projection  by sym from vertices;
        aa: m [a`sym];
        directionRadius: axis * b`sX;
        projectCircle: ((centerB - directionRadius) mmu axis; (centerB + directionRadius) mmu axis); 
        cMin: min projectCircle; 
        cMax: max projectCircle; 
        //show cMin;
        if [((aa`minP) >= cMax) or cMin >= aa`maxP;
            :emptyIntersectResult[];
        ];
        axisDepth: min(cMax-(aa`minP);(aa`maxP)-cMin); 
        if [axisDepth < depth;
            depth: axisDepth;
            normal: axis;
        ];
        i+:1;
    ];

    vertices: update circleCenter: count[i]#centerB from vertices;
    vertices: update distance: .physics.distanceV'[vector;circleCenter] from vertices;
    cp: raze exec vector from vertices where distance = min(distance);
    axis: cp - centerB;
    vertices: update projection: vector mmu axis from vertices;
    m: select minP:min projection, maxP:max projection  by sym from vertices;
    aa: m [a`sym];
    directionRadius: axis * b`sX;
    projectCircle: ((centerB - directionRadius) mmu axis; (centerB + directionRadius) mmu axis); 
    cMin: min projectCircle; 
    cMax: max projectCircle; 
    if [((aa`minP) >= cMax) or cMin >= aa`maxP;
        :emptyIntersectResult[];
    ];
    axisDepth: min(cMax-(aa`minP);(aa`maxP)-cMin); 
    if [axisDepth < depth;
        depth: axisDepth;
        normal: axis;
    ];

    centerA: getPositionVector[a];
    direction: normalise[centerB - centerA]; // vector pointing from A to B (to push B out of the way)
    normal: $[0f>direction mmu normal; -1*normal; normal];

    // if already moving away from each other then return
    if [0f < relativeVelocity[a;b] mmu normal; :emptyIntersectResult[]];

    :generatePostCollisionTransformations[a;b;normal;depth]};

intersectPlanes: {[pair]
    // Separating Axis Theorem (SAT)
    pair: update left: pX+sX%-2, bottom: pY+sY%-2 from pair;
    pair: update right: sX+left, top: sY+bottom from pair;
    pair: update LT: enlist'[left;top],
                 TR: enlist'[right;top], 
                 RB: enlist'[right;bottom], 
                 BL: enlist'[left;bottom] 
                from pair;

    vertices: unpivot[select sym,LT,TR,RB,BL from pair;`sym;`LT`TR`RB`BL;`vertex;`vector ];

    a:pair 0;
    b:pair 1;

    depth: 0w;
    normal: 0n;

    n: count vtx: `LT`TR`RB`BL;
    //check projections on vertices of a
    i:0;
    while[i<n;
        v1: a[ vtx i ];
        v2: a[ vtx (1+i) mod n ];
        edge: v2 - v1;
        axis: normalise[(-1*edge 1; edge 0)];
        vertices: update projection: vector mmu axis from vertices;
        m: select minP:min projection, maxP:max projection  by sym from vertices;
        aa: m [a`sym];
        bb: m [b`sym];
        if [((aa`minP) >= bb`maxP) or (bb`minP) >= aa`maxP;
            :emptyIntersectResult[];
        ];
        axisDepth: min((bb`maxP)-(aa`minP);(aa`maxP)-(bb`minP)); 
        if [axisDepth < depth;
            depth: axisDepth;
            normal: axis;
        ];
        i+:1;
    ];
    //check projections on vertices of b
    i:0;
    while[i<n;
        v1: b[ vtx i ];
        v2: b[ vtx (1+i) mod n ];
        edge: v2 - v1;
        axis: normalise[(-1*edge 1; edge 0)];
        vertices: update projection: vector mmu axis from vertices;
        m: select minP:min projection, maxP:max projection  by sym from vertices;
        aa: m [a`sym];
        bb: m [b`sym];
        if [((aa`minP) >= bb`maxP) or (bb`minP) >= aa`maxP;
            :emptyIntersectResult[];
        ];
        axisDepth: min((bb`maxP)-(aa`minP);(aa`maxP)-(bb`minP)); 
        if [axisDepth < depth;
            depth: axisDepth;
            normal: axis;
        ];
        i+:1;
    ];

    // need to make sure that the normal points from a to b
    // find the center of each box and check
    // show c: select center:sum(vector)%count(vector) by sym from vertices;
    // centerA: (c [a`sym])`center;
    // centerB: (c [b`sym])`center;

    centerA: getPositionVector[a];
    centerB: getPositionVector[b];

    direction: normalise[centerB - centerA]; // vector pointing from A to B (to push B out of the way)
    normal: $[0f>direction mmu normal; -1*normal; normal];

    // if already moving away from each other then return
    if [0f < relativeVelocity[a;b] mmu normal; :emptyIntersectResult[]];

    :generatePostCollisionTransformations[a;b;normal;depth]};

intersectCircle: {[pair]
    // show "intersectCircle";
    a:pair 0;
    b:pair 1;

    distance: distanceR[a;b];
    redi: (a`sX) + b`sX;

    if[distance >= redi; :emptyIntersectResult[]];

    centerA: getPositionVector[a];
    centerB: getPositionVector[b];

    normal: normalise[centerB - centerA]; // vector pointing from A to B (to push B out of the way)
    depth: redi-distance;

    // if already moving away from each other then return
    if [0f < relativeVelocity[a;b] mmu normal; :emptyIntersectResult[]];
    
    :generatePostCollisionTransformations[a;b;normal;depth]};





// Sort and Sweep collision detection
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

            if[ 
                (b`minX) < a`maxX;
                (a`maxY) > b`minY;
                (a`minY) < b`maxY;
                ast: a`static;
                bst: b`static;
                bothStatic: and[ast;bst];
                if [not bothStatic;
                    overlappingPairs: overlappingPairs upsert (a`sym;b`sym;a`shape;b`shape);
                ];
            ];
            j+:1;

        ];
        i+:1;
    ];
  :overlappingPairs};

resolveCollisions: {[state; pairs]
    n: count collidingSpheres: select from pairs where aShape = `sphere, bShape = `sphere;
    i:0;
    while [i<n;
        x: collidingSpheres i;
        k: (x`a),x`b;
        pair: select from state where sym in k;
        state: applyTransformations[state; intersectCircle[pair]];
        i+:1;
    ];

    n: count collidingPlanes: select from pairs where aShape = `plane, bShape = `plane;
    i:0;
    while [i<n;
        x: collidingPlanes i;
        k: (x`a),x`b;
        pair: select from state where sym in k;
        state: applyTransformations[state; intersectPlanes[pair]];
        i+:1;
    ];

    // make sure object a is the plane
    collidingPlaneSphere0: select from pairs where (aShape=`sphere), bShape=`plane;
    collidingPlaneSphere1: select from pairs where (aShape=`plane), bShape=`sphere;
    n: count collidingSP: collidingPlaneSphere0,collidingPlaneSphere1;
    i:0;
    while [i<n;
        x: collidingSP i;
        k: (x`a),x`b;
        pair: `shape xasc select from state where sym in k;
        state: applyTransformations[state; intersectBoxCircle[pair]];
        i+:1;
    ];            
  :state};

applyTransformations: {[state;t]
    if [not 0~count t;
        tmpState: state lj `sym xkey t;
        tmpState: delete pXn,pYn from update pX:pX+pXn, pY:pY+pYn from tmpState where not pXn=0n;
        state: delete vXn,vYn from update vX:vX+vXn, vY:vY+vYn from tmpState where not vXn=0n;
    ];
    :state};

// update functions
updateState: {[dict] 
    state: dict`state;
    input: dict`input;
    dt: dict`dt;
    if [not all 0=input;
        state: updatePositionsAndVelocitiesWithInput[state;input;dt]; 
    ]
    state: updatePositionsAndVelocities[state;dt]; 
    state: checkCollisions[state];
    :state};

updatePositionsAndVelocities: {[state; dt]
    / 1. Update velocity for X, Y components    
    state: update vX:vX+dt*aX, 
                  vY:vY+dt*(.physics.gravity+aY)
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
    invMass first exec invM from state where sym=`1;
    acc: .physics.acceleration[input;invMass];
    aXin: (acc 0);
    aYin: (acc 1);

    / 1. Update velocity for X, Y components 
    state: update vX:vX+dt*aXin, vY:vY+dt*aYin from state where sym = `1;   
    / 2. Update position for X, Y components 
    state: update pX:pX+dt*vX, pY:pY+dt*vY from state where sym = `1;   
    :state};
