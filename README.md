# **Physics Engine**

A server-driven physics engine built with **q** for kdb+ and visualized on the web using **THREE.js**. The engine simulates the motion of objects under gravity, handles collisions, and provides real-time updates via WebSockets.

![](./Physics2.gif)

---

## **Features**
- **Gravity Simulation**: Objects are influenced by a constant gravitational acceleration.
- **Collision Detection**:
  - **Axis-Aligned Bounding Boxes (AABB)**: Lightweight collision detection using rectangular bounds.
  - **Sort and Sweep Algorithm**: Optimized collision detection for multiple moving objects.
  - **Separating Axis Theorem (SAT)**: Used for accurate collision detection between convex polygons.
- **Real-Time Visualization**: Front-end integration with JavaScript to visualize objects' motion and collisions.

---

## **Collision Detection Algorithms**
### **1. Axis-Aligned Bounding Boxes (AABB)**
The **AABB** method uses rectangular bounds around objects for simple, efficient collision checks.

#### **Steps:**
1. Define a rectangle (bounding box) around each object.
2. Check for overlap using the minimum and maximum \( x \) and \( y \) coordinates:
   - Overlap conditions:
     \[
     x_{min1} < x_{max2} \text{ and } x_{max1} > x_{min2}
     \]
     \[
     y_{min1} < y_{max2} \text{ and } y_{max1} > y_{min2}
     \]

#### **Advantages:**
- Lightweight and computationally inexpensive.
- Ideal for simple or pre-filtering collision checks.

---

### **2. Sort and Sweep Algorithm**
The **Sort and Sweep** algorithm efficiently detects collisions in systems with multiple objects by reducing unnecessary checks.

#### **Steps:**
1. **Sort** objects by their minimum \( x \)-coordinates.
2. **Sweep** through the sorted list:
   - Compare only objects that overlap along the \( x \)-axis.

#### **Advantages:**
- Efficient for large numbers of objects.
- Reduces the number of pairwise checks.

---

### **3. Separating Axis Theorem (SAT)**
The **Separating Axis Theorem** determines whether two convex shapes intersect by projecting the vertices of the shapes onto potential separating axes. If projections overlap on all axes, the shapes collide.

#### **Steps:**
1. Identify all potential axes from the edges' normals of both shapes.
2. Project the vertices of both shapes onto each axis.
3. Check for projection overlap:
   - **Overlap** on all axes → Shapes collide.
   - **No overlap** on at least one axis → Shapes do not collide.

#### **Advantages:**
- Works for all convex shapes.
- Accurate and reliable.

---

## **How to Run**

### 1. Install dependancies for web
```bash
npm i
```

### 2. Run all together
```bash
npm run all
```

### or separately
1. Start **vite server**:
```bash
npx vite
```
2. Start the **q server**:
```bash
cd engine
q main.q
```


### TODO
- Friction
- Angular Momentum
- Refactoring / Optimisation

### References
- [Two-Bit Coding](https://www.youtube.com/@two-bitcoding8018)
- [Video Game Physics Tutorial - Part I: An Introduction to Rigid Body Dynamics](https://www.toptal.com/game/video-game-physics-part-i-an-introduction-to-rigid-body-dynamics)
- [Chris Hecker - Rigid Body Dynamics](https://www.chrishecker.com/Rigid_Body_Dynamics#Physics_References)
- [An Introduction to Physically Based Modeling](https://www.cs.cmu.edu/~baraff/sigcourse/notesd1.pdf)
- [Physics Tutorial 6: Collision Response](https://research.ncl.ac.uk/game/mastersdegree/gametechnologies/previousinformation/physics6collisionresponse/2017%20Tutorial%206%20-%20Collision%20Response.pdf)
- [Animation Loop](https://discoverthreejs.com/book/first-steps/animation-loop/)
