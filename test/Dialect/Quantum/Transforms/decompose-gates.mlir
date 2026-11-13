// RUN: quantum-opt %s --quantum-decompose-gates | FileCheck %s --check-prefix=UNCHANGED
// RUN: quantum-opt %s --pass-pipeline='builtin.module(quantum-decompose-gates{decompositions=quantum.CCX:qelib1},quantum-verify-linearity)' | FileCheck %s
// RUN: quantum-opt %s --quantum-decompose-gates='decompositions=CCX:qelib1' | FileCheck %s
// RUN: quantum-opt %s --quantum-decompose-gates='decompositions=Toffoli:qelib1' | FileCheck %s

// UNCHANGED: "quantum.CCX"
// CHECK-LABEL: func.func @toffoli(
// CHECK-SAME: %[[A:.*]]: !quantum.qubit<1>, %[[B:.*]]: !quantum.qubit<1>, %[[C:.*]]: !quantum.qubit<1>
func.func @toffoli(%a: !quantum.qubit<1>, %b: !quantum.qubit<1>, %c: !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
  // The checks follow qelib1.inc, including control-wire SSA updates.
  // CHECK-NEXT: %[[H:.*]] = "quantum.H"(%[[C]])
  // CHECK-NEXT: %[[B1:.*]], %[[C1:.*]] = "quantum.CNOT"(%[[B]], %[[H]])
  // CHECK-NEXT: %[[D1:.*]] = "quantum.Tdg"(%[[C1]])
  // CHECK-NEXT: %[[A1:.*]], %[[C2:.*]] = "quantum.CNOT"(%[[A]], %[[D1]])
  // CHECK-NEXT: %[[T1:.*]] = "quantum.T"(%[[C2]])
  // CHECK-NEXT: %[[B2:.*]], %[[C3:.*]] = "quantum.CNOT"(%[[B1]], %[[T1]])
  // CHECK-NEXT: %[[D2:.*]] = "quantum.Tdg"(%[[C3]])
  // CHECK-NEXT: %[[A2:.*]], %[[C4:.*]] = "quantum.CNOT"(%[[A1]], %[[D2]])
  // CHECK-NEXT: %[[T2:.*]] = "quantum.T"(%[[B2]])
  // CHECK-NEXT: %[[T3:.*]] = "quantum.T"(%[[C4]])
  // CHECK-NEXT: %[[H2:.*]] = "quantum.H"(%[[T3]])
  // CHECK-NEXT: %[[A3:.*]], %[[B3:.*]] = "quantum.CNOT"(%[[A2]], %[[T2]])
  // CHECK-NEXT: %[[T4:.*]] = "quantum.T"(%[[A3]])
  // CHECK-NEXT: %[[D3:.*]] = "quantum.Tdg"(%[[B3]])
  // CHECK-NEXT: %[[A4:.*]], %[[B4:.*]] = "quantum.CNOT"(%[[T4]], %[[D3]])
  // CHECK-NEXT: return %[[A4]], %[[B4]], %[[H2]]
  %x, %y, %z = "quantum.CCX"(%a, %b, %c) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>)
  return %x, %y, %z : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
}
