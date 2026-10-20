// RUN: quantum-qasm %S/Inputs/adder.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check successful lowering and representative circuit structure.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "majority"
// CHECK: sym_name = "unmaj"
// CHECK: sym_name = "main"
// CHECK-COUNT-4: callee = @majority
// CHECK-COUNT-4: callee = @unmaj
// CHECK-COUNT-5: "quantum.measure"(
// CHECK: "qpu.return"
// CHECK: func.func @qasm_main
// CHECK: qpu.execute @qasm_generated::@main
