system "l qunit.q"
system "l physicsTest.q"
system "c 100 105"

x: .qunit.runTests `.physicsTest;
show select status, name, result, msg from x;
// show x;
// .qunit.runTest `.physicsTest.testUpdateForce

system "\\"