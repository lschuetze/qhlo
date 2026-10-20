// RUN: quantum-qasm %S/Inputs/ipea_3_pi_8.qasm | FileCheck %s
// XFAIL: *
// Valid upstream program: its cu declaration conflicts with the embedded qelib1.inc.
// Remove XFAIL when the frontend accepts this program; keep success as the expectation.

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check successful lowering and representative circuit structure.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "cu"
// CHECK: sym_name = "main"
// CHECK: callee = @cu
// CHECK: "quantum.measure"(
// CHECK: scf.if
// CHECK: "qpu.return"
// CHECK: func.func @qasm_main
// CHECK: qpu.execute @qasm_generated::@main
