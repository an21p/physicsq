system "d .physics"

PI:3.141592653589793238;
gravity: -0.981f;

initState: {[] flip `sym`shape`m`pX`pY`pZ`vX`vY`vZ`fX`fY`fZ`rX`rY`rZ`sX`sY`sZ!"ssffffffffffffffff"$\:()};

initWithPlane: { 
    state: initState[];  
    state: addPlane[state];  
    :state};

addPlane: {[state] :state upsert (`planeX;`plane;1f;0f;0f;0f;0f;0f;0f;0f;-1*.physics.gravity;0f;-1*.physics.PI%2;0f;0f;1000f;1000f;1f)};

/ add x random elemenents to state
addRandomElements: {[state; x]
    r: 25f;
    elements: ([] sym: (`$ string each til x);   // unique id
                    shape: x#`sphere;               
                    m: x?1+til 3;                // mass up to 3
                    pX: -150+x?300;
                    pY: 1000+x?500;
                    pZ: x#0; 
                    vX: x#0; vY: x#0; vZ: x#0;
                    fX: x#0; fY: x#0; fZ: x#0;
                    rX: x#0; rY: x#0; rZ: x#0;
                    sX: x#r; sY: x#r; sZ: x#r);
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
            from state;
    / 2. Update position for X, Y, Z components 
    state: update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from state;
    :state};

    / 3. Update angular velocity for X, Y, Z components 
    / 4. Update rotation for X, Y, Z components (mod by 2π)
            // float angularAcceleration = rigidBody->torque / rigidBody->shape.momentOfInertia;
            // rigidBody->angularVelocity += angularAcceleration * dt;
            // rigidBody->angle += rigidBody->angularVelocity * dt;

/ Calculate AABB for all objects
calculateAABB:{[state] :update minX:pX-sX, maxX:pX+sX, minY:pY-sY, maxY:pY+sY, minZ:pZ-sZ, maxZ:pZ+sZ from state };

/ Sort and Sweep collision detection
sortAndSweepCollision:{[state]
  / 1. Calculate AABB for all objects
  stateWithAABB: calculateAABB[state];


  / 2. Sort by minX
  stateWithAABB: `minX xasc stateWithAABB;

  / 3. Sweep through and check overlaps
  overlappingPairs:();
  n:count stateWithAABB;

  do[n-1; { 
    show x;
    show "x";
    i:x; 
    a:stateWithAABB i;
    do[n-i-1; { 
      j:i+1+x; 
      b:stateWithAABB j;
      if[b`minX > a`maxX; break]; / No need to check further if b's minX > a's maxX
      if[
        (a`maxY > b`minY) & (a`minY < b`maxY) & 
        (a`maxZ > b`minZ) & (a`minZ < b`maxZ); 
        overlappingPairs,:((a`sym;b`sym)) 
      ]; 
    }] 
  }];

  :overlappingPairs
  };

checkCollisionsBroad: {[state]
  /show sortAndSweepCollision[state];
  :state};

checkCollisionsNarrow: {[state] :state};

checkCollisions: {[state] state: checkCollisionsBroad[state]; state: checkCollisionsNarrow[state]};

updateState: {[state] 
    state: applyForces[state]; 
    state: updatePositionsAndVelocities[state]; 
    state: checkCollisions[state];
    :state};
