// RUN: quantum-qasm %S/Inputs/W-state.qasm | FileCheck %s

// The unmodified upstream source and provenance are in Inputs/ and README.md.
// Check successful lowering and representative circuit structure.

// CHECK: qpu.module @qasm_generated
// CHECK: sym_name = "cH"
// CHECK: sym_name = "main"
// CHECK: callee = @cH
// CHECK-COUNT-3: "quantum.measure"(
// CHECK: "qpu.return"
// CHECK: func.func @qasm_main
// CHECK: qpu.execute @qasm_generated::@main
