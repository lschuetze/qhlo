// RUN: quantum-opt -hermitian-cancel -split-input-file %s | FileCheck %s

// Reversing control and target does not apply the same gate twice.
// CHECK-LABEL: func.func @reversed_cnot(
// CHECK-SAME: %[[A:.*]]: !quantum.qubit<1>, %[[B:.*]]: !quantum.qubit<1>
func.func @reversed_cnot(%a: !quantum.qubit<1>, %b: !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>) {
  // CHECK: %[[C:.*]], %[[D:.*]] = "quantum.CNOT"(%[[A]], %[[B]])
  %c, %d = "quantum.CNOT"(%a, %b) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[E:.*]], %[[F:.*]] = "quantum.CNOT"(%[[D]], %[[C]])
  %e, %f = "quantum.CNOT"(%d, %c) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: return %[[E]], %[[F]]
  return %e, %f : !quantum.qubit<1>, !quantum.qubit<1>
}

// -----

// Outputs of separate gate instances cannot form a cancellable pair.
// CHECK-LABEL: func.func @mixed_cnot(
func.func @mixed_cnot(%a: !quantum.qubit<1>, %b: !quantum.qubit<1>, %c: !quantum.qubit<1>, %d: !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>) {
  // CHECK: %[[E:.*]], %[[F:.*]] = "quantum.CNOT"
  %e, %f = "quantum.CNOT"(%a, %b) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[G:.*]], %[[H:.*]] = "quantum.CNOT"
  %g, %h = "quantum.CNOT"(%c, %d) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[I:.*]], %[[J:.*]] = "quantum.CNOT"(%[[E]], %[[H]])
  %i, %j = "quantum.CNOT"(%e, %h) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: return %[[F]], %[[G]], %[[I]], %[[J]]
  return %f, %g, %i, %j : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>
}
