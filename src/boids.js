import * as THREE from 'three';
import { Clock } from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GUI } from 'three/addons/libs/lil-gui.module.min.js';
import { debounce } from 'lodash-es';


function connect(initSettings) {    
    if ("WebSocket" in window) {
        ws = new WebSocket("ws://localhost:5002");
        ws.onopen = (e) => {
            /* on successful connection, we want to create an
             initial subscription to load all the data into the page*/ 
             ws.send('{"action": "loadPage"}');             
             initSettings.forEach((s)=> ws.send(s));
        };
        ws.onmessage = (e) => {
            /*parse message from JSON String into Object*/ 
            // console.log(e.data);            
            var d = JSON.parse(e.data);
            /*depending on the messages func value, pass the result
            to the appropriate handler function*/ 
            switch (d.func) {
                case 'getState':
                    animate(d.result);
                    const delta = clock.getDelta();
                    // setTimeout(()=> {
                        ws.send(`{"action": "update", "delta": ${delta}}`);
                    // },25);
            }
        };
        ws.onclose = (e) => {
            console.log("disconnected");
        };
        ws.onerror = (e) => {
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

function onDocumentMouseMove( event ) {
    mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1;
	mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1;
    planeNormal.copy(camera.position).normalize();
    plane.setFromNormalAndCoplanarPoint(planeNormal, scene.position);
    raycaster.setFromCamera(mouse, camera);
    raycaster.ray.intersectPlane(plane, intersectionPoint);
    // console.log(intersectionPoint);
    ws.send(`{"action": "mouse", "x": ${intersectionPoint.x}, "y": ${intersectionPoint.y}}`);
    // console.table(intersectionPoint);
    
}

function addNewObjects(state) {
    state.forEach((element) => {
        if (element.sym in shapes) return;
    
        let object; 
        let color = 0xa1a1de;
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


    // Create an orthographic camera
    const aspect = window.innerWidth / window.innerHeight;
    const frustumSize = 5000;
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
    camera.zoom = .5;
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
    controls.enableRotate = false;
    controls.enablePan = false;

    controls.addEventListener( 'change', () => {renderer.render( scene, camera )} ); // call this only in static scenes (i.e., if there is no animation loop)
    controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 200;
    controls.maxDistance = 2000;

    controls.maxPolarAngle = Math.PI / 2;

    // panel
    const panel = new GUI( { width: 310 } );
    const rule0 = panel.addFolder( 'Rule 0: Tendancy to zero' );
    const rule1 = panel.addFolder( 'Rule 1: Boids try to fly towards the centre of mass' );
    const rule2 = panel.addFolder( 'Rule 2: Boids try to keep a small distance away' );
    const rule3 = panel.addFolder( 'Rule 3: Boids try to match velocity with near boids' );
    const maxSpeed = panel.addFolder( 'Rule *: Limit max speed' );
    const settings = {
        ruleZeroScale: 0.025,
        ruleOneScale: 0.02,
        ruleTwoScale: 0.5,
        ruleTwoDisance: 55.0,
        ruleThreeScale: 0.25,
        maxSpeed: 180.0,
    };

    rule0.add(settings, 'ruleZeroScale', 0, 0.1, 0.001).name('Scale').onChange(value => {
        ws.send(`{"action": "settings", "key": "ruleZeroScale", "value":${value}}`);
    });    
    rule1.add(settings, 'ruleOneScale', 0, 0.03, 0.001).name('Scale').onChange(value => {
        ws.send(`{"action": "settings", "key": "ruleOneScale", "value":${value}}`);
    });
    rule2.add(settings, 'ruleTwoScale', 0, 1, 0.05).name('Scale').onChange(value => {
        ws.send(`{"action": "settings", "key": "ruleTwoScale", "value":${value}}`);
    });
    rule2.add(settings, 'ruleTwoDisance', 0, 200, 1).name('Distance').onChange(value => {
        ws.send(`{"action": "settings", "key": "ruleTwoDisance", "value":${value}}`);
    });
    rule3.add(settings, 'ruleThreeScale', 0, 1, 0.01).name('Scale').onChange(value => {
        ws.send(`{"action": "settings", "key": "ruleThreeScale", "value":${value}}`);
    });
    maxSpeed.add(settings, 'maxSpeed', 0, 350, 1).name('Max Speed').onChange(value => {
        ws.send(`{"action": "settings", "key": "maxSpeed", "value":${value}}`);
    });

    // ws
    window.addEventListener("DOMContentLoaded", () => {
        console.log("load");
        let initSettings = Object.keys(settings).map((s)=> {
            return `{"action": "settings", "key":"${s}", "value":${settings[s]}}`;      
          });
        connect(initSettings);
    });

    // mouse 
    const delay = 0;
    const debounced = debounce((e) => {onDocumentMouseMove(e)}, delay);
    
    document.addEventListener("mousemove", (e) => {debounced(e) }, false);


}
const clock = new Clock();

let ws, renderer, controls, camera, scene
let shapes = {};

// mouse click
const mouse = new THREE.Vector2();
const intersectionPoint = new THREE.Vector3();
const planeNormal = new THREE.Vector3();
const plane = new THREE.Plane();
const raycaster = new THREE.Raycaster();

init();