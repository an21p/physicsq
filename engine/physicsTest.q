system "l physics.q";
system "d .physicsTest";

trap: {[x] 
    .Q.trp[parse;x;{1@.Q.sbt 2#y}]}

initSimpleMocked: {
    r:10f;
    mockState: .physics.initWithPlane[];
    mockState: mockState upsert (`1;`sphere;1f;-10f;10f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r;0b);
    mockState: mockState upsert (`2;`sphere;1f;10f;10f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r;0b);
    mockState: mockState upsert (`3;`sphere;0f;-1000f;10f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r;0b); // no mass

    // apply force equal to -1*gravity to keep them at the same point
    mockState: update fY: -1*.physics.gravity from mockState where shape=`sphere;
    :mockState}

testInitSize:{ .qunit.assertEquals[count .physics.initWithPlane[] ; 1; "init state has 1 element"]; :`pass};		
testInitPlane:{ .qunit.assertEquals[count select from .physics.initWithPlane[] where shape=`plane; 1; "init state has plane"]; :`pass};	

testAddElements:{
    n: 50;
    mockState: .physics.initWithPlane[];
    endState: .physics.addRandomElements[mockState;n];
    .qunit.assertEquals[count select from endState where shape=`plane; 1; "still has 1 plane"];
    .qunit.assertEquals[count select from endState where shape=`sphere; n; "added spheres"];
    :`pass}

testUpdateNoForce:{
    mockState: .physicsTest.initSimpleMocked[];
    s0: select sym,pX,pY,pZ,vX,vY,vZ from mockState;
    mockState: .physics.updatePositionsAndVelocities[mockState];
    s1: select sym,pX,pY,pZ,vX,vY,vZ from mockState;
    .qunit.assertEquals[s0; s1; "no moves"];
    :`pass}

testUpdateForce:{
    mockState: .physicsTest.initSimpleMocked[];

    // apply force of 1 on x-axis to all 
    // velocity should increment by 1
    // position should increment by 1
    mockState: update fX: 1f from mockState where shape=`sphere;
    s1v: update vX:vX+.physics.acceleration[fX;invM] from mockState;
    s1p: update pX:pX+vX from s1v;
    s1e: select sym,pX,pY,pZ,vX,vY,vZ from s1p;
    mockState: .physics.updatePositionsAndVelocities[mockState];
    s1actual: select sym,pX,pY,pZ,vX,vY,vZ from mockState;
    .qunit.assertEquals[s1actual; s1e; "moves based on x force"];

    // stop applying force
    // velocity stays the same
    // position should increment by 1
    mockState: update fX: 0f from mockState where shape=`sphere;
    s2p: update pX:pX+vX from mockState;
    s2e: select sym,pX,pY,pZ,vX,vY,vZ from s2p;
    mockState: .physics.updatePositionsAndVelocities[mockState];
    s2actual: select sym,pX,pY,pZ,vX,vY,vZ from mockState;
    .qunit.assertEquals[s2actual; s2e; "moves based on velocity"];


    // apply force of -1 on x-axis to all 
    // velocity decrements by 1
    // position stays the same
    mockState: update fX: -1f from mockState where shape=`sphere;
    s3e: update vX:0 from s2e;
    mockState: .physics.updatePositionsAndVelocities[mockState];
    s3actual: select sym,pX,pY,pZ,vX,vY,vZ from mockState;
    .qunit.assertEquals[s3actual; s3e; "no moves (velocity back to 0)"];

    :`pass}

testAABBEdge: {[]
    mockState: .physicsTest.initSimpleMocked[];
    // with a sX (radius) = 10 for each sphere
    // if pX_1 = -10 and pX_2 = 10 
    // the edge should touch at 0 
    
    aabb: .physics.calculateAABB[mockState];
    s1: select sym, minX, maxX from aabb where sym in `1`2;
    s1expeted: ([] sym: `1`2; minX: -20 0; maxX: 0 20);
    .qunit.assertEquals[s1; s1expeted; "correct placement on x-axis"];

    // show select from .physics.state;

    :`pass}

testAABB: {[]
    mockState: .physicsTest.initSimpleMocked[];
    // with a sX (radius) = 10 for each sphere
    // if pX_1 = -9 and pX_2 = 10 
    // they should collide

    mockState: update pX: -9f, vX: 1f, fX: 0f from mockState where sym=`1;
    
    aabb: .physics.calculateAABB[mockState];
    s1: select sym, minX, maxX from aabb where sym in `1`2;
    s1expeted: ([] sym: `1`2; minX: -19 0; maxX: 1 20);

    .qunit.assertEquals[s1; s1expeted; "correct placement on x-axis"];

    // show select from .physics.state;

    :`pass}

testCollisionDetectionNoCollision: {[]
    show "testCollisionDetectionNoCollision";
    mockState: .physicsTest.initSimpleMocked[];
    mockState: update pX: -11f, vX: 1f, fX: 0f from mockState where sym=`1;

    pairs: .physics.sortAndSweepCollision[mockState];
    collidingSpheres: select from pairs where aShape = `sphere, bShape = `sphere;
    show pairs;
    .qunit.assertEquals[count collidingSpheres; 0; "should contain no collisions"];
    :`pass}

testCollisionDetectionEdge: {[]
    show "testCollisionDetectionEdge";

    mockState: .physicsTest.initSimpleMocked[];

    pairs: .physics.sortAndSweepCollision[mockState];
    collidingSpheres: select from pairs where aShape = `sphere, bShape = `sphere;
    .qunit.assertEquals[count collidingSpheres; 0; "should contain no collisions"];
    :`pass}

testCollisionDetectionSortAndSweep: {[]
    show "testCollisionDetectionSortAndSweep";

    mockState: .physicsTest.initSimpleMocked[];
    mockState: update pX: -9f, vX: 1f, fX: 0f from mockState where sym=`1;

    pairs: .physics.sortAndSweepCollision[mockState];
    collidingSpheres: select from pairs where aShape = `sphere, bShape = `sphere;
    .qunit.assertEquals[count collidingSpheres; 1; "should contain 1 collision"];
    .qunit.assertEquals[collidingSpheres`a; `1];
    .qunit.assertEquals[collidingSpheres`b; `2];
    :`pass}

testCollisionSpheres: {[]
    show "testCollisionSpheres";

    mockState: .physicsTest.initSimpleMocked[];
    mockState: update pX: -9f, vX: 1f, fX: 0f from mockState where sym=`1;
    // mockState: update pX: 19f, vX: 1f, fX: 0f from mockState where sym=`3;
    show s1: .physics.checkCollisions[mockState];
    show s2: .physics.checkCollisions[s1];
    //.qunit.assertEquals[; ; "should contain 1 collision"];
    :`fail;
    :`pass}


testNormalise: {[]
    nv: .physics.normalise[(9;0;0f)];
    .qunit.assertEquals[nv; (1f;0f;0f); "correct normaliseation"];

    :`pass}

testDistnaceSpheres: {[]
    mockState: .physicsTest.initSimpleMocked[];
    mockState: update pX: -9f, vX: 1f, fX: 0f from mockState where sym=`1;

    pair: select from mockState where sym in `1`2;
    a:pair 0;
    b:pair 1;
    d: .physics.distanceSpheres[a;b];
    .qunit.assertEquals[d; 19f; "correct distance between sphere centers"];
    :`pass}