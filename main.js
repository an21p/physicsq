import * as THREE from 'three';
import { TrackballControls } from 'three/addons/controls/TrackballControls.js';

function connect() {
    if ("WebSocket" in window) {
        ws = new WebSocket("ws://localhost:5001");
        ws.onopen = function (e) {
            /* on successful connection, we want to create an
             initial subscription to load all the data into the page*/ ws.send('{"action": "loadPage"}');
        };
        ws.onmessage = function (e) {
            /*parse message from JSON String into Object*/ var d = JSON.parse(e.data);
            /*depending on the messages func value, pass the result
            to the appropriate handler function*/ switch (d.func) {
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

window.addEventListener("DOMContentLoaded", function () {
    console.log("load");
    connect();
});

function addNewObjects(state) {
    state.forEach((element) => {
        if (element.sym in shapes) return;

        let object;
        switch (element.shape) {
            case "poly":
                throw new Error("not implemented");
                break;
            case "shpere":
            default:
                object = new THREE.Mesh(new THREE.SphereGeometry(20, 20, 20), new THREE.MeshPhysicalMaterial({flatShading: true}));
                break;
        }
        object.position.setX(element.pX);
        object.position.setY(element.pY);
        object.position.setZ(element.pZ);   
        shapes[element.sym] = object;
        scene.add(object);
    })
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

    controls.update();
    renderer.render(scene, camera);
}

let ws;
let shapes = {};

let plane = new THREE.Mesh(new THREE.PlaneGeometry(400, 400), new THREE.MeshBasicMaterial({color: 0xa1a1a1}));
plane.position.y = -200;
plane.rotation.x = -Math.PI / 2;

let camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 2000);
camera.position.y = 10;
camera.position.z = 1500;

let pointLight1 = new THREE.PointLight(0xffffff, 5, 0, 0); pointLight1.position.set(300, 300, 300);
let pointLight2 = new THREE.PointLight(0xffffff, 1, 0, 0); pointLight2.position.set(-500, -500, -500);

let axesHelper = new THREE.AxesHelper(1000);
let scene = new THREE.Scene();
scene.background = new THREE.Color(0, 0, 0);
scene.add(pointLight1);
scene.add(pointLight2);
scene.add(plane);
scene.add(axesHelper);

let renderer = new THREE.WebGLRenderer(); renderer.setSize(window.innerWidth, window.innerHeight);

var controls = new TrackballControls(camera, renderer.domElement); 

// renderer.setAnimationLoop( animate );

document.body.appendChild(renderer.domElement);
