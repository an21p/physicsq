import * as THREE from 'three';

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

window.addEventListener( "load", () => {
	console.log("load");
	connect();
})


const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );

const renderer = new THREE.WebGLRenderer();
renderer.setSize( window.innerWidth, window.innerHeight );
// renderer.setAnimationLoop( animate );
document.body.appendChild( renderer.domElement );

const geometry = new THREE.BoxGeometry( 1, 1, 1 );
const material = new THREE.MeshBasicMaterial( { color: 0xe3e3e3 } );
const cube = new THREE.Mesh( geometry, material );
cube.position.x += 1;
scene.add( cube );

const planeGeometry = new THREE.PlaneGeometry( 2, 2 ); 
const planeMaterial = new THREE.MeshBasicMaterial( {color: 0xffff00, side: THREE.DoubleSide} ); 
const plane = new THREE.Mesh( planeGeometry, planeMaterial ); 
scene.add( plane );
plane.position.x -= 1;


camera.position.z = 5;

function animate() {    
	cube.rotation.x += 0.02;
	cube.rotation.y += 0.01;

	plane.rotation.x += 0.01;
	plane.rotation.y += 0.01;

	renderer.render( scene, camera );

}


function update(state) {    
	console.log("update");
	
	cube.rotation.x += 0.02;
	cube.rotation.y += 0.01;

	plane.rotation.x += 0.01;
	plane.rotation.y += 0.01;

	renderer.render( scene, camera );

}