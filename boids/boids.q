\l ../engine/physics.q
\d .boids

initState: {[n]
    state: .physics.createCircles[n];
    state: .physics.checkCollisions[state];
    :state};

// update functions
updateState: {[dict] 
    state: dict`state;
    dt: dict`dt;
    state: .physics.updatePositionsAndVelocities[state;dt]; 
    :state};