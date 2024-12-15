system "d .physics"

PI:3.141592653589793238;
gravity: -0.981f;
state:flip `sym`shape`m`pX`pY`pZ`vX`vY`vZ`fX`fY`fZ`rX`rY`rZ`sX`sY`sZ!"ssffffffffffffffff"$\:();

initState: {[] delete from `.physics.state; addPlane[] };
addPlane: {[] `.physics.state insert (`planeX;`plane;1f;0f;0f;0f;0f;0f;0f;0f;-1*.physics.gravity;0f;-1*.physics.PI%2;0f;0f;1000f;1000f;1f)};

/ add x random elemenents to state
addRandomElements: {[x]
    elements: ([] sym: (`$ string each til x);    // unique id
                    shape: x#`sphere;               
                    m: x?1+til 3;                // mass up to 3
                    pX: -150+x?300;
                    pY: 1000+x?500;
                    pZ: x#0; 
                    vX: x#0; vY: x#0; vZ: x#0;
                    fX: x#0; fY: x#0; fZ: x#0;
                    rX: x#0; rY: x#0; rZ: x#0;
                    sX: x#50; sY: x#50; sZ: x#50);
    .physics.state: .physics.state,elements;
 }

/ return the current state
getState: {[] select sym,shape,pX,pY,pZ,rX,rY,rZ,sX,sY,sZ from `.physics.state };

applyForces: {[]};

acceleration: {[force; mass] acc:force%mass; acc[where abs[acc]=0w]:0n; :0^acc };

updatePositionsAndVelocities: {[]
    / 1. Update velocity for X, Y, Z components 
    update  
        vX:vX+.physics.acceleration[fX;m], 
        vY:vY+.physics.acceleration[.physics.gravity+fY;m], 
        vZ:vZ+.physics.acceleration[fZ;m]
    from `.physics.state;
    / 2. Update position for X, Y, Z components 
    update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from `.physics.state;

    };

/ Calculate AABB for all objects
calculateAABB:{[]
  update 
    minX:pX-(sX%2), maxX:pX+(sX%2), 
    minY:pY-(sY%2), maxY:pY+(sY%2), 
    minZ:pZ-(sZ%2), maxZ:pZ+(sZ%2) 
  from `.physics.state
  }

/ Sort and Sweep collision detection
sortAndSweepCollision:{[]
  / 1. Calculate AABB for all objects
  calculateAABB[];

  / 2. Sort by minX
  sorted:asc .physics.state`minX;
  .physics.state:.physics.state@sorted;

  / 3. Sweep through and check overlaps
  overlappingPairs:();
  n:count .physics.state;
  do[n-1; { 
    i:x; 
    a:.physics.state i;
    do[n-i-1; { 
      j:i+1+x; 
      b:.physics.state j;
      if[b`minX > a`maxX; break]; / No need to check further if b's minX > a's maxX
      if[
        (a`maxY > b`minY) & (a`minY < b`maxY) & 
        (a`maxZ > b`minZ) & (a`minZ < b`maxZ); 
        overlappingPairs,:((a`sym;b`sym)) 
      ]; 
    }] 
  }];

  :overlappingPairs
  }

collisionBroad: {[]
  /show sortAndSweepCollision[];
  };

collisionNarrow: {[]};

collisions: {[] collisionBroad[]; collisionNarrow[]};

updateState: {[] 
    applyForces[]; 
    updatePositionsAndVelocities[]; 
    collisions[]
 };
