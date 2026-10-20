// RUN: quantum-qasm %S/Inputs/bigadder.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check successful lowering and representative circuit structure.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "add4"
// CHECK: sym_name = "main"
// CHECK-COUNT-2: callee = @add4
// CHECK-COUNT-9: "quantum.measure"(
// CHECK: "qpu.return"
// CHECK: func.func @qasm_main
// CHECK: qpu.execute @qasm_generated::@main
