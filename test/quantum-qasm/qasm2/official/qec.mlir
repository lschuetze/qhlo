// RUN: quantum-qasm %S/Inputs/qec.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check successful lowering and representative circuit structure.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "syndrome"
// CHECK: sym_name = "main"
// CHECK: callee = @syndrome
// CHECK-COUNT-2: "quantum.measure"(
// CHECK-COUNT-3: scf.if
// CHECK-COUNT-3: "quantum.measure"(
// CHECK: "qpu.return"
// CHECK: func.func @qasm_main
// CHECK: qpu.execute @qasm_generated::@main
