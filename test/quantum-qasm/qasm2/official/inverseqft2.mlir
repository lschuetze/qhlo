// RUN: quantum-qasm %S/Inputs/inverseqft2.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check successful lowering and representative circuit structure.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "main"
// CHECK: "quantum.measure"(
// CHECK-COUNT-6: scf.if
// CHECK: "quantum.measure"(
// CHECK: "qpu.return"
// CHECK: func.func @qasm_main
// CHECK: qpu.execute @qasm_generated::@main
