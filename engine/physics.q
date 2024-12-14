\d .physics

gravity: -0.981f;
state:flip `sym`shape`m`pX`pY`pZ`vX`vY`vZ`fX`fY`fZ!"ssffffffffff"$\:();

initState: {[] delete from `.physics.state };
addElement: {[] 
    `.physics.state insert (`a;`sphere;1f;0f;1000f;0f;0f;1f;0f;0f;0f;0f)
 };
addRandomElements: {[x]
    elements: ([] sym: (`$ string each til x);    // unique id
                    shape: x#`sphere;               
                    m: x?1+til 3;                // mass up to 3
                    pX: -150+x?300;
                    pY: 1000+x?500;
                    pZ: x#0; 
                    vX: x#0; vY: x#0; vZ: x#0;
                    fX: x#0; fY: x#0; fZ: x#0);
    .physics.state: .physics.state,elements;
 }
getState: {[] select sym,shape,pX,pY,pZ from state };

updateState: {[] 
    / 1. Update velocity for X, Y, Z components 
    update  vX:vX+(fX%m), vY:vY+((.physics.gravity+fY)%m), vZ:vZ+(fZ%m) from `.physics.state;
    / 2. Update position for X, Y, Z components 
    update pX:pX+vX, pY:pY+vY, pZ:pZ+vZ from `.physics.state;

    }
