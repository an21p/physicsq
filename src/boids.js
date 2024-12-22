import * as THREE from 'three';
import { Clock } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const clock = new Clock();

function connect() {
    if ("WebSocket" in window) {
        ws = new WebSocket("ws://localhost:5002");
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
                case 'getState':
                    animate(d.result);
                    const delta = clock.getDelta();
                    ws.send(`{"action": "update", "delta": ${delta}}`);
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

function createCircle(e, color) {
    return new THREE.Mesh(
        new THREE.CircleGeometry(e.sX, 100), new THREE.MeshBasicMaterial({color: color}));
}

function createRectangle(e, color) {
    return new THREE.Mesh(
        new THREE.PlaneGeometry(e.sX, e.sY), new THREE.MeshBasicMaterial({color: color}));
}

function setPositionAndRotation(o, e) {
    o.position.x = e.pX;
    o.position.y = e.pY;
    o.rotation.x = e.theta;
    return o;
}

function addNewObjects(state) {
    state.forEach((element) => {
        if (element.sym in shapes) return;
    
        let object; 
        let color = 0xa1a1a1;
        if (element.sym === "1") color = 0xff0000;
        
        switch (element.shape) {
            case "poly":
                throw new Error("not implemented");
            case "plane":
                if (element.sym.startsWith("plane")) color = 0xdede01
                object =  createRectangle(element,color)
                break;
            case "shpere":
            default:
                object = createCircle(element,color);
                break;
        }
        setPositionAndRotation(object, element);
        shapes[element.sym] = object;
        object.layers.enableAll();
        scene.add(object);
    })
}

function animate(state) {    
    state.forEach((element) => {
        if (element.static) return;
        if (!(element.sym in shapes)) return;

        let object = shapes[element.sym];
        object.position.x = element.pX;
        object.position.y = element.pY;
    });
    addNewObjects(state);

    renderer.render(scene, camera);
}

function init() {
    window.addEventListener('resize', () => {
        const aspect = window.innerWidth / window.innerHeight;
        camera.left = frustumSize * aspect / -2;
        camera.right = frustumSize * aspect / 2;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });
    
    // renderer
    renderer = new THREE.WebGLRenderer(); renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);

    // ws
    window.addEventListener("DOMContentLoaded", function () {
        console.log("load");
        connect();
    });

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
    camera.position.z = 10; // Position the camera away from the square
    // camera.position.z = 500; // Position the camera away from the square
    camera.zoom = 0.7;
    camera.updateProjectionMatrix();

    // lights
    let pointLight1 = new THREE.PointLight(0xffffff, 5, 0, 0); pointLight1.position.set(0, 0, 300);
    let pointLight2 = new THREE.PointLight(0xffffff, 1, 0, 0); pointLight2.position.set(0, 0, -500);

    // scene
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0, 0, 0);
    scene.add(pointLight1);
    scene.add(pointLight2);

    //controls
    controls = new OrbitControls( camera, renderer.domElement );
    controls.listenToKeyEvents( window ); // optional

    controls.addEventListener( 'change', () => {renderer.render( scene, camera )} ); // call this only in static scenes (i.e., if there is no animation loop)
    controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 200;
    controls.maxDistance = 2000;

    controls.maxPolarAngle = Math.PI / 2;
}

let ws, renderer, controls, camera, scene
let shapes = {};
init();