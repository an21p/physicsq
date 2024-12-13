\d .physics

gravity: -2.8f;

state:flip `sym`pX`pY`pZ`vX`vY`vZ`aX`aY`aZ!"sfffffffff"$\:();
`state insert (`a;0f;1000f;0f;0f;1f;0f;0f;0f;0f);

getState: {[] select sym,pX,pY,pZ from state};

updateState: {[] 
    / 1. Update velocity for X, Y, Z components 
    update  vX:vX+aX, vY:vY+.physics.gravity, vZ:vZ+aZ from `.physics.state;
    / 2. Update position for X, Y, Z components 
    update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from `.physics.state;

    }
