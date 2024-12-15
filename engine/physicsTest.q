system "l physics.q";
system "d .physicsTest";

addInitElements: {
    r:10f;
    `.physics.state insert (`1;`sphere;1f;-50f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r);
    `.physics.state insert (`2;`sphere;1f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r);
    `.physics.state insert (`3;`sphere;0f;50f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;0f;r;r;r); // no mass

    // apply force equal to -1*gravity to keep them at the same point
    update fY: -1*.physics.gravity from `.physics.state where shape=`sphere;}

setUpState: {.physics.initState[]};

testInitSize:{ .qunit.assertEquals[count .physics.state ; 1; "init state has 1 element"]; :`pass};		
testInitPlane:{ .qunit.assertEquals[count select from .physics.state where shape=`plane; 1; "init state has plane"]; :`pass};	

testAddElements:{
    n: 50;
    .physics.addRandomElements[n];
    .qunit.assertEquals[count select from .physics.state where shape=`plane; 1; "still has 1 plane"];
    .qunit.assertEquals[count select from .physics.state where shape=`sphere; n; "added spheres"];
    :`pass}

testUpdateNoForce:{
    .physicsTest.addInitElements[];
    s0: select sym,pX,pY,pZ,vX,vY,vZ from .physics.state;
    .physics.updatePositionsAndVelocities[];
    s1: select sym,pX,pY,pZ,vX,vY,vZ from .physics.state;
    .qunit.assertEquals[s0; s1; "no moves"];
    :`pass}

testUpdateForce:{
    .physicsTest.addInitElements[];

    // apply force of 1 on x-axis to all 
    // velocity should increment by 1
    // position should increment by 1
    update fX: 1f from `.physics.state where shape=`sphere;
    s1v: update vX:vX+.physics.acceleration[fX;m] from .physics.state;
    s1p: update pX:pX+vX from s1v;
    s1e: select sym,pX,pY,pZ,vX,vY,vZ from s1p;
    .physics.updatePositionsAndVelocities[];
    s1actual: select sym,pX,pY,pZ,vX,vY,vZ from .physics.state;
    .qunit.assertEquals[s1actual; s1e; "moves based on x force"];

    // stop applying force
    // velocity stays the same
    // position should increment by 1
    update fX: 0f from `.physics.state where shape=`sphere;
    s2p: update pX:pX+vX from .physics.state;;
    s2e: select sym,pX,pY,pZ,vX,vY,vZ from s2p;
    .physics.updatePositionsAndVelocities[];
    s2actual: select sym,pX,pY,pZ,vX,vY,vZ from .physics.state;
    .qunit.assertEquals[s2actual; s2e; "moves based on velocity"];


    // apply force of -1 on x-axis to all 
    // velocity decrements by 1
    // position stays the same
    update fX: -1f from `.physics.state where shape=`sphere;
    s3e: update vX:0 from s2e;
    .physics.updatePositionsAndVelocities[];
    s3actual: select sym,pX,pY,pZ,vX,vY,vZ from .physics.state;
    .qunit.assertEquals[s3actual; s3e; "no moves (velocity back to 0)"];
    
    :`pass}
