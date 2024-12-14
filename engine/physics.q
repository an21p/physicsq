\d .physics

gravity: -0.981f;
state:flip `sym`shape`m`pX`pY`pZ`vX`vY`vZ`fX`fY`fZ!"ssffffffffff"$\:();

initState: {[] delete from `.physics.state };
addElement: {[] `.physics.state insert (`a;`sphere;1f;0f;1000f;0f;0f;1f;0f;0f;0f;0f) };
getState: {[] select sym,shape,pX,pY,pZ from state };

updateState: {[] 
    / 1. Update velocity for X, Y, Z components 
    update  vX:vX+(fX%m), vY:vY+((.physics.gravity+fY)%m), vZ:vZ+(fZ%m) from `.physics.state;
    / 2. Update position for X, Y, Z components 
    update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from `.physics.state;

    }
