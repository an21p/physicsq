import * as THREE from 'three';
import { TrackballControls } from 'three/addons/controls/TrackballControls.js';

let ws;
function connect() {
    if ("WebSocket" in window) {
        ws = new WebSocket("ws://localhost:5001");
        ws.onopen = function(e) {
            /* on successful connection, we want to create an
             initial subscription to load all the data into the page*/
            ws.send("loadPage[]");
        };

        ws.onmessage = function(e) {
            /*parse message from JSON String into Object*/
            var d = JSON.parse(e.data);

            /*depending on the messages func value, pass the result
            to the appropriate handler function*/
			switch(d.func){
				// case 'getSyms'   : setSyms(d.result); break;
				// case 'getQuotes' : setQuotes(d.result); break;
				case 'getState' : update(d.result); 
            }
        };

        ws.onclose = function(e){ console.log("disconnected")};
        ws.onerror = function(e){ console.log(e.data)};
    } else alert("WebSockets not supported on your browser.");
}
window.addEventListener( "DOMContentLoaded", () => {
	console.log("load");
	connect();
})


function animate() {    
	console.log(camera.rotation);
	

	controls.update();
	renderer.render( scene, camera );
}

function update(state) {    


	controls.update();
	renderer.render( scene, camera );
}


const scene = new THREE.Scene();
scene.background = new THREE.Color( 0, 0, 0 );

const camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 1, 1000 );
camera.position.y = 150;
camera.position.z = 500;

const pointLight1 = new THREE.PointLight( 0xffffff, 5, 0, 0 );
pointLight1.position.set( 300, 300, 300 );
scene.add( pointLight1 );

const pointLight2 = new THREE.PointLight( 0xffffff, 1, 0, 0 );
pointLight2.position.set( - 500, - 500, - 500 );
scene.add( pointLight2 );

const sphere = new THREE.Mesh( new THREE.SphereGeometry( 50, 50, 50 )
							, new THREE.MeshPhysicalMaterial( { flatShading: true } ) 
						);
scene.add( sphere );

const renderer = new THREE.WebGLRenderer();
renderer.setSize( window.innerWidth, window.innerHeight );
document.body.appendChild( renderer.domElement );

const plane = new THREE.Mesh( new THREE.PlaneGeometry( 400, 400 )
							, new THREE.MeshBasicMaterial( { color: 0xa1a1a1 } ) 
						);
plane.position.y = - 200;
plane.rotation.x = - Math.PI / 2;
scene.add( plane );

const axesHelper = new THREE.AxesHelper( 1000 ); 
scene.add( axesHelper );

let controls = new TrackballControls( camera, renderer.domElement );

// renderer.setAnimationLoop( animate );
// renderer.render( scene, camera );

