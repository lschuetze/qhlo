// RUN: timeout 30 quantum-opt --quantum-phase-poly-merge --quantum-verify-linearity -split-input-file %s | FileCheck %s --enable-var-scope

// Runtime conditions preserve both branch paths and zero-trip loop exits.
// Explicit Rz gates exercise phase merging without native T/Tdg normalization.

// Based on Feynman if-simple. Both paths preserve the control parity.
module {
qpu.module @test [#qpu.target<qubits = 3, coupling = []>] {
// CHECK-LABEL: sym_name = "if_preserves_control_parity"
"qpu.circuit"() <{function_type = (i1, f64, f64) -> (), sym_name = "if_preserves_control_parity"}> ({
^bb0(%cond: i1, %alpha: f64, %beta: f64):
  // CHECK: ^bb0(%[[COND:.*]]: i1, %[[ALPHA:.*]]: f64, %[[BETA:.*]]: f64):
  // CHECK: %[[A:.*]] = "quantum.alloc"
  %a = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[B:.*]] = "quantum.alloc"
  %b = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[SUM:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ:.*]] = "quantum.Rz"(%[[A]], %[[SUM]])
  %a1 = "quantum.Rz"(%a, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[IF:.*]]:2 = scf.if %[[COND]]
  %out:2 = scf.if %cond -> (!quantum.qubit<1>, !quantum.qubit<1>) {
    // CHECK-NEXT: %[[CXA:.*]], %[[CXB:.*]] = "quantum.CNOT"(%[[RZ]], %[[B]])
    %a2, %b2 = "quantum.CNOT"(%a1, %b) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    // CHECK-NEXT: scf.yield %[[CXA]], %[[CXB]]
    scf.yield %a2, %b2 : !quantum.qubit<1>, !quantum.qubit<1>
  } else {
    // CHECK: scf.yield %[[RZ]], %[[B]]
    scf.yield %a1, %b : !quantum.qubit<1>, !quantum.qubit<1>
  }
  // CHECK-NOT: "quantum.Rz"
  %a3 = "quantum.Rz"(%out#0, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: "quantum.deallocate"(%[[IF]]#0)
  "quantum.deallocate"(%a3) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[IF]]#1)
  "quantum.deallocate"(%out#1) : (!quantum.qubit<1>) -> ()
  "qpu.return"() : () -> ()
}) : () -> ()
}
}

// -----

// Exclusive rotations execute on different paths. Their angles are branch-local.
module {
qpu.module @test [#qpu.target<qubits = 3, coupling = []>] {
// CHECK-LABEL: sym_name = "if_keeps_exclusive_rotations"
"qpu.circuit"() <{function_type = (i1, f64, f64) -> (), sym_name = "if_keeps_exclusive_rotations"}> ({
^bb0(%cond: i1, %alpha: f64, %beta: f64):
  // CHECK: ^bb0(%[[COND:.*]]: i1, %[[ALPHA:.*]]: f64, %[[BETA:.*]]: f64):
  // CHECK-NEXT: %[[A:.*]] = "quantum.alloc"
  %a = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK-NEXT: %[[IF:.*]] = scf.if %[[COND]]
  %out = scf.if %cond -> (!quantum.qubit<1>) {
    // CHECK-NEXT: %[[THETA:.*]] = arith.negf %[[ALPHA]] : f64
    %theta = arith.negf %alpha : f64
    // CHECK-NEXT: %[[THEN:.*]] = "quantum.Rz"(%[[A]], %[[THETA]])
    %a1 = "quantum.Rz"(%a, %theta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
    // CHECK-NEXT: scf.yield %[[THEN]]
    scf.yield %a1 : !quantum.qubit<1>
  // CHECK-NEXT: } else {
  } else {
    // CHECK-NEXT: %[[PHI:.*]] = arith.negf %[[BETA]] : f64
    %phi = arith.negf %beta : f64
    // CHECK-NEXT: %[[ELSE:.*]] = "quantum.Rz"(%[[A]], %[[PHI]])
    %a2 = "quantum.Rz"(%a, %phi) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
    // CHECK-NEXT: scf.yield %[[ELSE]]
    scf.yield %a2 : !quantum.qubit<1>
  // CHECK-NEXT: }
  }
  // CHECK-NEXT: "quantum.deallocate"(%[[IF]])
  "quantum.deallocate"(%out) : (!quantum.qubit<1>) -> ()
  "qpu.return"() : () -> ()
}) : () -> ()
}
}

// -----

// Based on Feynman loop-simple, loop-h and loop-null. Only outer phases merge.
module {
qpu.module @test [#qpu.target<qubits = 3, coupling = []>] {
// CHECK-LABEL: sym_name = "loop_preserves_control_phase"
"qpu.circuit"() <{function_type = (i64, f64, f64, f64) -> (), sym_name = "loop_preserves_control_phase"}> ({
^bb0(%limit: i64, %alpha: f64, %beta: f64, %gamma: f64):
  // CHECK: ^bb0(%[[LIMIT:.*]]: i64, %[[ALPHA:.*]]: f64, %[[BETA:.*]]: f64, %[[GAMMA:.*]]: f64):
  // CHECK: %[[A:.*]] = "quantum.alloc"
  %a = "quantum.alloc"() : () -> !quantum.qubit<1>
  %b = "quantum.alloc"() : () -> !quantum.qubit<1>
  %c = "quantum.alloc"() : () -> !quantum.qubit<1>
  %zero = arith.constant 0 : i64
  %one = arith.constant 1 : i64
  // CHECK: %[[SUM:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ:.*]] = "quantum.Rz"(%[[A]], %[[SUM]])
  %a1 = "quantum.Rz"(%a, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[LOOP:.*]]:4 = scf.while (%{{.*}} = %[[RZ]],
  %out:4 = scf.while (%qa = %a1, %qb = %b, %qc = %c, %i = %zero) : (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, i64) -> (!quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, i64) {
    %cond = arith.cmpi slt, %i, %limit : i64
    scf.condition(%cond) %qa, %qb, %qc, %i : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, i64
  } do {
  // CHECK: ^bb0(%[[QA:.*]]: !quantum.qubit<1>, %[[QB:.*]]: !quantum.qubit<1>, %[[QC:.*]]: !quantum.qubit<1>, %[[I:.*]]: i64):
  ^bb0(%qa: !quantum.qubit<1>, %qb: !quantum.qubit<1>, %qc: !quantum.qubit<1>, %i: i64):
    // CHECK-NEXT: %[[CXA:.*]], %[[CXB:.*]] = "quantum.CNOT"(%[[QA]], %[[QB]])
    %a2, %b2 = "quantum.CNOT"(%qa, %qb) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    // CHECK-NEXT: %[[H:.*]] = "quantum.H"(%[[QC]])
    %c2 = "quantum.H"(%qc) : (!quantum.qubit<1>) -> !quantum.qubit<1>
    // CHECK-NEXT: %[[BODY:.*]] = "quantum.Rz"(%[[CXA]], %[[GAMMA]])
    %a3 = "quantum.Rz"(%a2, %gamma) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
    // CHECK-NEXT: %[[NEXT:.*]] = arith.addi %[[I]],
    %next = arith.addi %i, %one : i64
    // CHECK-NEXT: scf.yield %[[BODY]], %[[CXB]], %[[H]], %[[NEXT]]
    scf.yield %a3, %b2, %c2, %next : !quantum.qubit<1>, !quantum.qubit<1>, !quantum.qubit<1>, i64
  }
  // CHECK-NOT: "quantum.Rz"
  %a4 = "quantum.Rz"(%out#0, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: "quantum.deallocate"(%[[LOOP]]#0)
  "quantum.deallocate"(%a4) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[LOOP]]#1)
  "quantum.deallocate"(%out#1) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[LOOP]]#2)
  "quantum.deallocate"(%out#2) : (!quantum.qubit<1>) -> ()
  "qpu.return"() : () -> ()
}) : () -> ()
}
}

// -----

// Based on Feynman loop-swap. SWAP preserves XOR parity but changes individual wire parity.
module {
qpu.module @test [#qpu.target<qubits = 3, coupling = []>] {
// CHECK-LABEL: sym_name = "loop_swap_preserves_xor_phase"
"qpu.circuit"() <{function_type = (i64, f64, f64) -> (), sym_name = "loop_swap_preserves_xor_phase"}> ({
^bb0(%limit: i64, %alpha: f64, %beta: f64):
  // CHECK: ^bb0(%[[LIMIT:.*]]: i64, %[[ALPHA:.*]]: f64, %[[BETA:.*]]: f64):
  // CHECK: %[[A:.*]] = "quantum.alloc"
  %a = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK-NEXT: %[[B:.*]] = "quantum.alloc"
  %b = "quantum.alloc"() : () -> !quantum.qubit<1>
  %zero = arith.constant 0 : i64
  %one = arith.constant 1 : i64
  // CHECK: %[[PREA:.*]], %[[PREB:.*]] = "quantum.CNOT"(%[[A]], %[[B]])
  %a1, %b1 = "quantum.CNOT"(%a, %b) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NEXT: %[[SUM:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ:.*]] = "quantum.Rz"(%[[PREB]], %[[SUM]])
  %b2 = "quantum.Rz"(%b1, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[UNCOMPUTEA:.*]], %[[UNCOMPUTEB:.*]] = "quantum.CNOT"(%[[PREA]], %[[RZ]])
  %a3, %b3 = "quantum.CNOT"(%a1, %b2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NEXT: %[[LOOP:.*]]:3 = scf.while (%{{.*}} = %[[UNCOMPUTEA]], %{{.*}} = %[[UNCOMPUTEB]],
  %out:3 = scf.while (%qa = %a3, %qb = %b3, %i = %zero) : (!quantum.qubit<1>, !quantum.qubit<1>, i64) -> (!quantum.qubit<1>, !quantum.qubit<1>, i64) {
    %cond = arith.cmpi slt, %i, %limit : i64
    scf.condition(%cond) %qa, %qb, %i : !quantum.qubit<1>, !quantum.qubit<1>, i64
  } do {
  // CHECK: ^bb0(%[[QA:.*]]: !quantum.qubit<1>, %[[QB:.*]]: !quantum.qubit<1>, %[[I:.*]]: i64):
  ^bb0(%qa: !quantum.qubit<1>, %qb: !quantum.qubit<1>, %i: i64):
    // CHECK-NEXT: %[[SWAPA:.*]], %[[SWAPB:.*]] = "quantum.SWAP"(%[[QA]], %[[QB]])
    %sa, %sb = "quantum.SWAP"(%qa, %qb) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    // CHECK-NEXT: %[[NEXT:.*]] = arith.addi %[[I]],
    %next = arith.addi %i, %one : i64
    // CHECK-NEXT: scf.yield %[[SWAPA]], %[[SWAPB]], %[[NEXT]]
    scf.yield %sa, %sb, %next : !quantum.qubit<1>, !quantum.qubit<1>, i64
  }
  // CHECK-NEXT: %[[POSTA:.*]], %[[POSTB:.*]] = "quantum.CNOT"(%[[LOOP]]#0, %[[LOOP]]#1)
  %a4, %b4 = "quantum.CNOT"(%out#0, %out#1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NOT: "quantum.Rz"
  %b5 = "quantum.Rz"(%b4, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: %[[FINALA:.*]], %[[FINALB:.*]] = "quantum.CNOT"(%[[POSTA]], %[[POSTB]])
  %a6, %b6 = "quantum.CNOT"(%a4, %b5) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NEXT: "quantum.deallocate"(%[[FINALA]])
  "quantum.deallocate"(%a6) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[FINALB]])
  "quantum.deallocate"(%b6) : (!quantum.qubit<1>) -> ()
  "qpu.return"() : () -> ()
}) : () -> ()
}
}

// -----

// Based on Feynman loop-swap. SWAP preserves XOR parity but changes individual wire parity.
module {
qpu.module @test [#qpu.target<qubits = 3, coupling = []>] {
// CHECK-LABEL: sym_name = "loop_swap_changes_wire_phase"
"qpu.circuit"() <{function_type = (i64, f64, f64) -> (), sym_name = "loop_swap_changes_wire_phase"}> ({
^bb0(%limit: i64, %alpha: f64, %beta: f64):
  // CHECK: ^bb0(%[[LIMIT:.*]]: i64, %[[ALPHA:.*]]: f64, %[[BETA:.*]]: f64):
  // CHECK: %[[A:.*]] = "quantum.alloc"
  %a = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK-NEXT: %[[B:.*]] = "quantum.alloc"
  %b = "quantum.alloc"() : () -> !quantum.qubit<1>
  %zero = arith.constant 0 : i64
  %one = arith.constant 1 : i64
  // CHECK: %[[RZ:.*]] = "quantum.Rz"(%[[A]], %[[ALPHA]])
  %a3 = "quantum.Rz"(%a, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[LOOP:.*]]:3 = scf.while (%{{.*}} = %[[RZ]], %{{.*}} = %[[B]],
  %out:3 = scf.while (%qa = %a3, %qb = %b, %i = %zero) : (!quantum.qubit<1>, !quantum.qubit<1>, i64) -> (!quantum.qubit<1>, !quantum.qubit<1>, i64) {
    %cond = arith.cmpi slt, %i, %limit : i64
    scf.condition(%cond) %qa, %qb, %i : !quantum.qubit<1>, !quantum.qubit<1>, i64
  } do {
  // CHECK: ^bb0(%[[QA:.*]]: !quantum.qubit<1>, %[[QB:.*]]: !quantum.qubit<1>, %[[I:.*]]: i64):
  ^bb0(%qa: !quantum.qubit<1>, %qb: !quantum.qubit<1>, %i: i64):
    // CHECK-NEXT: %[[SWAPA:.*]], %[[SWAPB:.*]] = "quantum.SWAP"(%[[QA]], %[[QB]])
    %sa, %sb = "quantum.SWAP"(%qa, %qb) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
    // CHECK-NEXT: %[[NEXT:.*]] = arith.addi %[[I]],
    %next = arith.addi %i, %one : i64
    // CHECK-NEXT: scf.yield %[[SWAPA]], %[[SWAPB]], %[[NEXT]]
    scf.yield %sa, %sb, %next : !quantum.qubit<1>, !quantum.qubit<1>, i64
  }
  // CHECK-NEXT: %[[POST:.*]] = "quantum.Rz"(%[[LOOP]]#0, %[[BETA]])
  %a4 = "quantum.Rz"(%out#0, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: "quantum.deallocate"(%[[POST]])
  "quantum.deallocate"(%a4) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[LOOP]]#1)
  "quantum.deallocate"(%out#1) : (!quantum.qubit<1>) -> ()
  "qpu.return"() : () -> ()
}) : () -> ()
}
}
