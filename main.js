import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { CSS2DRenderer, CSS2DObject } from 'three/addons/renderers/CSS2DRenderer.js';

function connect() {
    if ("WebSocket" in window) {
        ws = new WebSocket("ws://localhost:5001");
        ws.onopen = function (e) {
            /* on successful connection, we want to create an
             initial subscription to load all the data into the page*/ 
             ws.send('{"action": "loadPage"}');
        };
        ws.onmessage = function (e) {
            /*parse message from JSON String into Object*/ 
            // console.log(e.data);            
            var d = JSON.parse(e.data);
            /*depending on the messages func value, pass the result
            to the appropriate handler function*/ 
            switch (d.func) {
                // case 'getSyms'   : setSyms(d.result); break;
                // case 'getQuotes' : setQuotes(d.result); break;
                case 'getState':
                    update(d.result);
            }
        };
        ws.onclose = function (e) {
            console.log("disconnected");
        };
        ws.onerror = function (e) {
            console.log(e.data);
        };
    } else alert("WebSockets not supported on your browser.");
}

function pad(num, scale=1000) {
    return String((num*scale).toFixed(0)).padStart(2,'0');
}

function toDebugString(e) {
    // console.log('0'+pad(e.pX));
    
    return `<div>p:(x:${pad(e.pX,1)}, y:${pad(e.pY,1)}, z:${pad(e.pZ,1)})</div>
            <div>v:(x:${pad(e.vX)}, y:${pad(e.vY)}, z:${pad(e.vZ)})</div>
            <div>f:(x:${pad(e.fX)}, y:${pad(e.fY)}, z:${pad(e.fZ)})</div>`;
}

function addNewObjects(state) {
    state.forEach((element) => {
        if (element.sym in shapes) return;

        let object; 
        let color = 0xff0000;
        
        switch (element.shape) {
            case "poly":
                throw new Error("not implemented");
            case "plane":
                object = new THREE.Mesh(new THREE.PlaneGeometry(element.sX, element.sY), new THREE.MeshBasicMaterial({color: 0xa1a1a1}));   
                break;
            case "shpere":
            default:
                if (element.sym === "1") color = 0xa1a1a1;
                object = new THREE.Mesh(new THREE.SphereGeometry(element.sX, element.sY, element.sZ), new THREE.MeshPhysicalMaterial({flatShading: true, color: color}));
                break;
        }
        object.position.x = element.pX;
        object.position.y = element.pY;
        object.position.z = element.pZ;   
        object.rotation.x = element.rX;
        object.rotation.y = element.rY;
        object.rotation.z = element.rZ; 
        shapes[element.sym] = object;
        object.layers.enableAll();
        scene.add(object);

        if (element.static) return;

        const objectDiv = document.createElement( 'div' );
        objectDiv.className = 'label';
        objectDiv.innerHTML = toDebugString(element);
        objectDiv.style.backgroundColor = 'transparent';
        objectDiv.style.color = 'white';
        objectDiv.style.fontSize = '12px';

        const objectLabel = new CSS2DObject( objectDiv );
        objectLabel.position.set( 50, 0, 0 );
        objectLabel.center.set( 0, 1 );
        object.add( objectLabel );
        objectLabel.layers.set( 0 );
    })
}

function render() {
    renderer.render( scene, camera );
}

function update(state) {
    Object.keys(controller).forEach(key=> { controller[key].pressed && controller[key].func() })
    
    state.forEach((element) => {
        if (element.static) return;
        if (!(element.sym in shapes)) return;

        let object = shapes[element.sym];
        let label = object.children[0];
        label.element.innerHTML = toDebugString(element);
        object.position.x = element.pX;
        object.position.y = element.pY;
        object.position.z = element.pZ;
    });
    addNewObjects(state);

    // controls.update();
    renderer.render(scene, camera);
    labelRenderer.render( scene, camera );
}


function onWindowResize(){
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize( window.innerWidth, window.innerHeight );
    labelRenderer.setSize( window.innerWidth, window.innerHeight );
}


function init() {
    window.addEventListener( 'resize', onWindowResize, false );

    // renderer
    renderer = new THREE.WebGLRenderer(); renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);

    labelRenderer = new CSS2DRenderer();
    labelRenderer.setSize( window.innerWidth, window.innerHeight );
    labelRenderer.domElement.style.position = 'absolute';
    labelRenderer.domElement.style.top = '0px';
    document.body.appendChild( labelRenderer.domElement );

    // ws
    window.addEventListener("DOMContentLoaded", function () {
        console.log("load");
        connect();
    });

    document.onkeydown = (e) => {
        if(controller[e.code]){    controller[e.code].pressed = true  }
    };

    document.onkeyup = (e) => {
        if(controller[e.code]){    controller[e.code].pressed = false  }
    };
    
    // camera
    camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 2000);
    camera.position.y = 50;
    camera.position.z = 500;

    // lights
    let pointLight1 = new THREE.PointLight(0xffffff, 5, 0, 0); pointLight1.position.set(300, 300, 300);
    let pointLight2 = new THREE.PointLight(0xffffff, 1, 0, 0); pointLight2.position.set(-500, -500, -500);

    // axis
    axesHelper = new THREE.AxesHelper(1000);

    // scene
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0, 0, 0);
    scene.add(pointLight1);
    scene.add(pointLight2);
    scene.add(axesHelper);


    //controls
    controls = new OrbitControls( camera, labelRenderer.domElement );
    controls.listenToKeyEvents( window ); // optional

    controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)
    controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 200;
    controls.maxDistance = 2000;

    controls.maxPolarAngle = Math.PI / 2;

}
const controller = {
    "KeyD" : {pressed: false, func: () =>  ws.send(`{"action": "move", "params": "right"}`) },
    "KeyA" : {pressed: false, func: () =>  ws.send(`{"action": "move", "params": "left"}`) },
    "KeyW" : {pressed: false, func: () =>  ws.send(`{"action": "move", "params": "up"}`) },
    "KeyS" : {pressed: false, func: () =>  ws.send(`{"action": "move", "params": "down"}`) },
    "KeyC" : {pressed: false, func: () =>  ws.send(`{"action": "move", "params": "in"}`) },
    "KeyX" : {pressed: false, func: () =>  ws.send(`{"action": "move", "params": "out"}`) },
}
let ws, renderer, controls, camera, axesHelper, scene, labelRenderer
let shapes = {};
init();