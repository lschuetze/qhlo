// RUN: quantum-opt --quantum-phase-poly-merge --quantum-verify-linearity %s | FileCheck %s --enable-var-scope

// Symbolic identities do not require a hardware target. Register elements and
// subsequent allocations must have distinct identities, local to each circuit.
module {
qpu.module @test {
// CHECK-LABEL: sym_name = "register_offsets"
"qpu.circuit"() <{function_type = (f64, f64) -> (), sym_name = "register_offsets"}> ({
^bb0(%alpha: f64, %beta: f64):
  // CHECK: ^bb0(%[[ALPHA:.*]]: f64, %[[BETA:.*]]: f64):
  // CHECK-NEXT: %[[REG:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
  %reg = "quantum.alloc"() : () -> !quantum.qubit<2>
  // CHECK-NEXT: %[[C:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %c = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK-NEXT: %[[SPLIT:.*]]:2 = "quantum.split"(%[[REG]])
  %a, %b = "quantum.split"(%reg) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NEXT: %[[SUM0:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ0:.*]] = "quantum.Rz"(%[[SPLIT]]#0, %[[SUM0]])
  %a1 = "quantum.Rz"(%a, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %a2 = "quantum.Rz"(%a1, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[SUM1:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ1:.*]] = "quantum.Rz"(%[[SPLIT]]#1, %[[SUM1]])
  %b1 = "quantum.Rz"(%b, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %b2 = "quantum.Rz"(%b1, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[SUM2:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ2:.*]] = "quantum.Rz"(%[[C]], %[[SUM2]])
  %c1 = "quantum.Rz"(%c, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %c2 = "quantum.Rz"(%c1, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: "quantum.deallocate"(%[[RZ0]])
  "quantum.deallocate"(%a2) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[RZ1]])
  "quantum.deallocate"(%b2) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[RZ2]])
  "quantum.deallocate"(%c2) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "qpu.return"()
  "qpu.return"() : () -> ()
}) : () -> ()

// CHECK-LABEL: sym_name = "independent_circuit"
"qpu.circuit"() <{function_type = (f64, f64) -> (), sym_name = "independent_circuit"}> ({
^bb0(%alpha: f64, %beta: f64):
  // CHECK: ^bb0(%[[ALPHA:.*]]: f64, %[[BETA:.*]]: f64):
  // CHECK-NEXT: %[[REG:.*]] = "quantum.alloc"() : () -> !quantum.qubit<2>
  %reg = "quantum.alloc"() : () -> !quantum.qubit<2>
  // CHECK-NEXT: %[[C:.*]] = "quantum.alloc"() : () -> !quantum.qubit<1>
  %c = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK-NEXT: %[[SPLIT:.*]]:2 = "quantum.split"(%[[REG]])
  %a, %b = "quantum.split"(%reg) : (!quantum.qubit<2>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NEXT: %[[SUM0:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ0:.*]] = "quantum.Rz"(%[[SPLIT]]#0, %[[SUM0]])
  %a1 = "quantum.Rz"(%a, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %a2 = "quantum.Rz"(%a1, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[SUM1:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ1:.*]] = "quantum.Rz"(%[[SPLIT]]#1, %[[SUM1]])
  %b1 = "quantum.Rz"(%b, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %b2 = "quantum.Rz"(%b1, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: %[[SUM2:.*]] = arith.addf %[[ALPHA]], %[[BETA]] : f64
  // CHECK-NEXT: %[[RZ2:.*]] = "quantum.Rz"(%[[C]], %[[SUM2]])
  %c1 = "quantum.Rz"(%c, %alpha) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %c2 = "quantum.Rz"(%c1, %beta) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NEXT: "quantum.deallocate"(%[[RZ0]])
  "quantum.deallocate"(%a2) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[RZ1]])
  "quantum.deallocate"(%b2) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "quantum.deallocate"(%[[RZ2]])
  "quantum.deallocate"(%c2) : (!quantum.qubit<1>) -> ()
  // CHECK-NEXT: "qpu.return"()
  "qpu.return"() : () -> ()
}) : () -> ()

}
}
