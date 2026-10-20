// RUN: quantum-qasm %S/Inputs/qpt.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check successful lowering and representative circuit structure.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "pre"
// CHECK: sym_name = "post"
// CHECK: sym_name = "main"
// CHECK: callee = @pre
// CHECK: "quantum.H"(
// CHECK: callee = @post
// CHECK: "quantum.measure"(
// CHECK: "qpu.return"
// CHECK: func.func @qasm_main
// CHECK: qpu.execute @qasm_generated::@main
