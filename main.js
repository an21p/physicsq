import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

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

function addNewObjects(state) {
    state.forEach((element) => {
        if (element.sym in shapes) return;

        let object;
        switch (element.shape) {
            case "poly":
                throw new Error("not implemented");
                break;
            case "plane":
                object = new THREE.Mesh(new THREE.PlaneGeometry(element.sX, element.sY), new THREE.MeshBasicMaterial({color: 0xa1a1a1}));   
                break;
            case "shpere":
            default:
                object = new THREE.Mesh(new THREE.SphereGeometry(element.sX, element.sY, element.sZ), new THREE.MeshPhysicalMaterial({flatShading: true}));
                break;
        }
        object.position.setX(element.pX);
        object.position.setY(element.pY);
        object.position.setZ(element.pZ);   
        object.rotation.x = element.rX;
        object.rotation.y = element.rY;
        object.rotation.z = element.rZ; 
        shapes[element.sym] = object;
        scene.add(object);
    })
}

function render() {
    renderer.render( scene, camera );
}

function update(state) {

    state.forEach((element) => {
        if (!(element.sym in shapes)) return;

        let object = shapes[element.sym];
        object.position.setX(element.pX);
        object.position.setY(element.pY);
        object.position.setZ(element.pZ);    
    });
    addNewObjects(state);

    // controls.update();
    renderer.render(scene, camera);
}

function init() {

    // renderer
    renderer = new THREE.WebGLRenderer(); renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);

    // ws
    window.addEventListener("DOMContentLoaded", function () {
        console.log("load");
        connect();
    });
    
    // camera
    camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 2000);
    camera.position.y = 100;
    camera.position.z = 1500;

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

    let object1 = new THREE.Mesh(new THREE.SphereGeometry(10, 10, 10), new THREE.MeshPhysicalMaterial({flatShading: true}));
    object1.position.setX(-10);
    object1.position.setY(100);
    object1.position.setZ(0);   
    
    let object2 = new THREE.Mesh(new THREE.SphereGeometry(10, 10, 10), new THREE.MeshPhysicalMaterial({flatShading: true}));
    object2.position.setX(10);
    object2.position.setY(100);
    object2.position.setZ(0);   

    scene.add(object1);
    scene.add(object2);

    scene.add(axesHelper);

    //controls
    controls = new OrbitControls( camera, renderer.domElement );
    controls.listenToKeyEvents( window ); // optional

    controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)
    controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 200;
    controls.maxDistance = 2000;

    controls.maxPolarAngle = Math.PI / 2;

}

let ws, renderer, controls, camera, axesHelper, scene
let shapes = {};
init();