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

function createCircle(e, color = 0xa1a1a1) {
    return new THREE.Mesh(
        new THREE.CircleGeometry(e.sX, 100), new THREE.MeshBasicMaterial({color: color}));
}

function createRectangle(e, color = 0xa1a1a1) {
    return new THREE.Mesh(
        new THREE.PlaneGeometry(e.sX, e.sY), new THREE.MeshBasicMaterial({color: color}));
}

function setPositionAndRotation(o, e) {
    o.position.x = e.pX;
    o.position.y = e.pY;
    //o.position.z = e.pZ;   
    o.rotation.x = e.rX;
    o.rotation.y = e.rY;
    //o.rotation.z = e.rZ;
    return o;
}

function addNewObjects(state) {
    state.forEach((element) => {
        if (element.sym in shapes) return;

        let object; 
        
        switch (element.shape) {
            case "poly":
                throw new Error("not implemented");
            case "plane":
                object =  createRectangle(element)
                break;
            case "shpere":
            default:
                if (element.sym === "1") object = createCircle(element, 0xff0000);
                else object = createCircle(element);
                break;
        }
        setPositionAndRotation(object, element);
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
        label.visible = showDebugInfo;

        // object.position.z = element.pZ;
    });
    addNewObjects(state);

    // controls.update();
    renderer.render(scene, camera);
    labelRenderer.render( scene, camera );
}


function init() {
    window.addEventListener('resize', () => {
        const aspect = window.innerWidth / window.innerHeight;
        camera.left = frustumSize * aspect / -2;
        camera.right = frustumSize * aspect / 2;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
        labelRenderer.setSize( window.innerWidth, window.innerHeight );
    });
    
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

    // Create an orthographic camera
    const aspect = window.innerWidth / window.innerHeight;
    const frustumSize = 1000;
    camera = new THREE.OrthographicCamera(
        frustumSize * aspect / - 2, 
        frustumSize * aspect / 2,
        frustumSize / 2, 
        frustumSize / - 2, 
        1, 
        1000
    );
    camera.position.z = 500; // Position the camera away from the square

    // lights
    let pointLight1 = new THREE.PointLight(0xffffff, 5, 0, 0); pointLight1.position.set(0, 0, 300);
    let pointLight2 = new THREE.PointLight(0xffffff, 1, 0, 0); pointLight2.position.set(0, 0, -500);

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
    "KeyC" : {pressed: false, func: () =>  ws.send(`{"action": "create", "params": "circle"}`) },
    "KeyX" : {pressed: false, func: () =>  ws.send(`{"action": "create", "params": "rectangle"}`) },
    "KeyQ" : {pressed: false, func: () => showDebugInfo = !showDebugInfo },
}
let ws, renderer, controls, camera, axesHelper, scene, labelRenderer
let shapes = {};
let showDebugInfo = false;
init();