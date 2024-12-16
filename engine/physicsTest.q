system "l physics.q";
system "d .physicsTest";

initSimpleMocked: {
    r:10f;
    mockState: .physics.initWithPlane[];
    mockState: mockState upsert (`1;`sphere;1f;-10f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r);
    mockState: mockState upsert (`2;`sphere;1f;10f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r);
    mockState: mockState upsert (`3;`sphere;0f;-1000f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r); // no mass

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
    s1v: update vX:vX+.physics.acceleration[fX;m] from mockState;
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

testCollision: {[]
    mockState: .physicsTest.initSimpleMocked[];
    // with a sX (radius) = 10 for each sphere
    // if sX_1 = -10 and sX_2 = 10 
    // the edge should touch at 0 
    
    .physics.calculateAABB[mockState];
    .physics.addRandomElements[1];

    // show select from .physics.state;

    :`pass}
