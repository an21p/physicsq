\l qunit.q
\l physicsTest.q
\c 100 115

x: .qunit.runTests `.physicsTest;

// show x;
// x: .qunit.runTest `.physicsTest.testCollision;
show select status, name, result, msg from x;

system "\\"