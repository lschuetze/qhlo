// RUN: quantum-opt --quantum-phase-poly-merge -split-input-file %s | FileCheck %s

//                                          ┌───────────┐          
// q_0: ───────────────■─────────────────■──┤ Rz(0.987) ├──■───|0>─
//      ┌───────────┐┌─┴─┐┌───────────┐┌─┴─┐├───────────┤┌─┴─┐     
// q_1: ┤ Rz(0.321) ├┤ X ├┤ Rz(0.123) ├┤ X ├┤ Rz(0.567) ├┤ X ├─|0>─
//      └───────────┘└───┘└───────────┘└───┘└───────────┘└───┘     

// CHECK: module {
module {
// CHECK: qpu.module @test
qpu.module @test [#qpu.target<qubits = 3, coupling = [[0, 1], [1, 2]]>] {
// CHECK: "qpu.circuit"() <{function_type = (f64, f64, f64, f64) -> (), sym_name = "simple_rz_cancelling"}> ({
"qpu.circuit"() <{function_type = (f64, f64, f64, f64) -> (), sym_name = "simple_rz_cancelling"}>({
  // CHECK: ^bb0(%[[T1:.+]]: {{.*}}, %[[T2:.+]]: {{.*}}, %[[T3:.+]]: {{.*}}, %[[T4:.+]]: {{.*}}):
  ^bb0(%theta1: f64, %theta2: f64, %theta3: f64, %theta4: f64):
  // CHECK: %[[X0:.+]] = "quantum.alloc"() <{pos = 0 : i32}> : () -> !quantum.qubit<1>
  %x0 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK: %[[Y0:.+]] = "quantum.alloc"() <{pos = 1 : i32}> : () -> !quantum.qubit<1>
  %y0 = "quantum.alloc"() : () -> (!quantum.qubit<1>)
  // CHECK: %[[P:.+]] = arith.addf %[[T1]], %[[T4]] : f64
  // CHECK: %[[Y1:.+]] = "quantum.Rz"(%[[Y0]], %[[P]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %y1 = "quantum.Rz"(%y0, %theta1) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
  // CHECK: %[[X2:.+]], %[[Y2:.+]] = "quantum.CNOT"(%[[X0]], %[[Y1]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x2, %y2 = "quantum.CNOT" (%x0, %y1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[Y3:.+]] = "quantum.Rz"(%[[Y2]], %[[T2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %y3 = "quantum.Rz"(%y2, %theta2) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
  // CHECK: %[[X4:.+]], %[[Y4:.+]] = "quantum.CNOT"(%[[X2]], %[[Y3]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x4, %y4 = "quantum.CNOT" (%x2, %y3) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[X5:.+]] = "quantum.Rz"(%[[X4]], %[[T3]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %x5 = "quantum.Rz"(%x4, %theta3) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
  // CHECK-NOT: %[[Y5:.+]] = "quantum.Rz"(%[[Y4]], %[[T4]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %y5 = "quantum.Rz"(%y4, %theta4) : (!quantum.qubit<1>, f64) -> (!quantum.qubit<1>)
  // CHECK: %[[X6:.+]], %[[Y6:.+]] = "quantum.CNOT"(%[[X5]], %[[Y4]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)  
  %x6, %y6 = "quantum.CNOT" (%x5, %y5) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: "quantum.deallocate"(%[[X6]])
  "quantum.deallocate"(%x6) : (!quantum.qubit<1>) -> ()
  // CHECK: "quantum.deallocate"(%[[Y6]])
  "quantum.deallocate"(%y6) : (!quantum.qubit<1>) -> ()
  "qpu.return"() : () -> ()
}) : () -> ()
}
}

// -----

// CHECK: module {
module {
// CHECK: qpu.module @test
qpu.module @test [#qpu.target<qubits = 3, coupling = [[0, 1], [1, 2]]>] {
  // CHECK: "qpu.circuit"() <{function_type = (f64, f64, f64, f64) -> (), sym_name = "rz_with_h_cancelling"}> ({
"qpu.circuit"() <{function_type = (f64, f64, f64, f64) -> (), sym_name = "rz_with_h_cancelling"}>({
  // CHECK: ^bb0(%[[T1:.+]]: {{.*}}, %[[T2:.+]]: {{.*}}, %[[T3:.+]]: {{.*}}, %[[T4:.+]]: {{.*}}):
  ^bb0(%theta1: f64, %theta2: f64, %theta3: f64, %theta4: f64):
  // CHECK: %[[X0:.+]] = "quantum.alloc"() <{pos = 0 : i32}> : () -> !quantum.qubit<1>
  %x0 = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[Y0:.+]] = "quantum.alloc"() <{pos = 1 : i32}> : () -> !quantum.qubit<1>
  %y0 = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[Z0:.+]] = "quantum.alloc"() <{pos = 2 : i32}> : () -> !quantum.qubit<1>
  %z0 = "quantum.alloc"() : () -> !quantum.qubit<1>

  // CHECK: %[[X1:.+]] = "quantum.H"(%[[X0]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %x1 = "quantum.H"(%x0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  // CHECK: %[[Y1:.+]] = "quantum.H"(%[[Y0]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %y1 = "quantum.H"(%y0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  // CHECK: %[[Z1:.+]] = "quantum.H"(%[[Z0]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %z1 = "quantum.H"(%z0) : (!quantum.qubit<1>) -> !quantum.qubit<1>

  // CHECK: %[[P:.+]] = arith.addf %[[T1]], %[[T4]] : f64
  // CHECK: %[[Y2:.+]] = "quantum.Rz"(%[[Y1]], %[[P]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1> 
  %y2 = "quantum.Rz"(%y1, %theta1) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: %[[Z2:.+]] = "quantum.Rz"(%[[Z1]], %[[T2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %z2 = "quantum.Rz"(%z1, %theta2) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>

  // CHECK: %[[Y3:.+]], %[[X3:.+]] = "quantum.CNOT"(%[[Y2]], %[[X1]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %y3, %x3 = "quantum.CNOT"(%y2, %x1) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

  // CHECK: %[[X4:.+]] = "quantum.Rz"(%[[X3]], %[[T3]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %x4 = "quantum.Rz"(%x3, %theta3) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: %[[Y4:.+]], %[[Z4:.+]] = "quantum.CNOT"(%[[Y3]], %[[Z2]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %y4, %z4 = "quantum.CNOT"(%y3, %z2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

  // CHECK: %[[X5:.+]], %[[Y5:.+]] = "quantum.CNOT"(%[[X4]], %[[Y4]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x5, %y5 = "quantum.CNOT"(%x4, %y4) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[Z5:.+]] = "quantum.H"(%[[Z4]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %z5 = "quantum.H"(%z4) : (!quantum.qubit<1>) -> !quantum.qubit<1>

  // CHECK: %[[Y6:.+]], %[[Z6:.+]] = "quantum.CNOT"(%[[Y5]], %[[Z5]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %y6, %z6 = "quantum.CNOT"(%y5, %z5) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

  // CHECK: %[[X7:.+]], %[[Y7:.+]] = "quantum.CNOT"(%[[X5]], %[[Y6]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x7, %y7 = "quantum.CNOT"(%x5, %y6) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NOT: "quantum.Rz"(%[[Y7]], %[[T4]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %y8 = "quantum.Rz"(%y7, %theta4) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>

  // CHECK: %[[X9:.+]] = "quantum.H"(%[[X7]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %x9 = "quantum.H"(%x7) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  // CHECK: %[[Y9:.+]] = "quantum.H"(%[[Y7]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %y9 = "quantum.H"(%y8) : (!quantum.qubit<1>) -> !quantum.qubit<1>

  // CHECK: "quantum.deallocate"(%[[X9]])
  "quantum.deallocate"(%x9) : (!quantum.qubit<1>) -> ()
  // CHECK: "quantum.deallocate"(%[[Y9]])
  "quantum.deallocate"(%y9) : (!quantum.qubit<1>) -> ()
  // CHECK: "quantum.deallocate"(%[[Z6]])
  "quantum.deallocate"(%z6) : (!quantum.qubit<1>) -> ()
  "qpu.return"() : () -> ()
}) : () -> ()
}
}

// -----

// CHECK: module {
module {
// CHECK: qpu.module @test
qpu.module @test [#qpu.target<qubits = 3, coupling = [[0, 1], [1, 2]]>] {
  // CHECK: "qpu.circuit"() <{function_type = (f64, f64) -> (), sym_name = "rz_diff_wires_cancelling"}> ({
"qpu.circuit"() <{function_type = (f64, f64) -> (), sym_name = "rz_diff_wires_cancelling"}>({
  // CHECK: ^bb0(%[[T1:.+]]: {{.*}}, %[[T2:.+]]: {{.*}}):
  ^bb0(%theta1: f64, %theta2: f64):

  // CHECK: %[[X0:.+]] = "quantum.alloc"() <{pos = 0 : i32}> : () -> !quantum.qubit<1>
  %x0 = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[Y0:.+]] = "quantum.alloc"() <{pos = 1 : i32}> : () -> !quantum.qubit<1>
  %y0 = "quantum.alloc"() : () -> !quantum.qubit<1>

  // CHECK: %[[X1:.+]], %[[Y1:.+]] = "quantum.CNOT"(%[[X0]], %[[Y0]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x1, %y1 = "quantum.CNOT"(%x0, %y0) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

  // CHECK: %[[P:.+]] = arith.addf %[[T1]], %[[T2]] : f64
  // CHECK: %[[Y2:.+]] = "quantum.Rz"(%[[Y1]], %[[P]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %y2 = "quantum.Rz"(%y1, %theta1) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>

  // CHECK: %[[X3:.+]], %[[Y3:.+]] = "quantum.CNOT"(%[[X1]], %[[Y2]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x3, %y3 = "quantum.CNOT"(%x1, %y2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

  // CHECK: %[[Y4:.+]], %[[X4:.+]] = "quantum.CNOT"(%[[Y3]], %[[X3]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %y4, %x4 = "quantum.CNOT"(%y3, %x3) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)

  // CHECK-NOT: %[[X5:.+]] = "quantum.Rz"(%[[X4]], %[[T2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %x5 = "quantum.Rz"(%x4, %theta2) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>

  // CHECK: %[[Y6:.+]], %[[X6:.+]] = "quantum.CNOT"(%[[Y4]], %[[X4]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %y6, %x6 = "quantum.CNOT"(%y4, %x5) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>) 

  // CHECK: "quantum.deallocate"(%[[X6]])
  "quantum.deallocate"(%x6) : (!quantum.qubit<1>) -> ()
  // CHECK: "quantum.deallocate"(%[[Y6]])
  "quantum.deallocate"(%y6) : (!quantum.qubit<1>) -> ()  

  "qpu.return" () : () -> ()
}) : () -> ()
}
}

// -----

// CHECK: module {
module {
// CHECK: qpu.module @test
qpu.module @test [#qpu.target<qubits = 3, coupling = [[0, 1], [1, 2]]>] {
  // CHECK: "qpu.circuit"() <{function_type = (f64, f64, f64, f64) -> (), sym_name = "merge_rz_diff_h"}> ({
"qpu.circuit"() <{function_type = (f64, f64, f64, f64) -> (), sym_name = "merge_rz_diff_h"}>({
  // CHECK: ^bb0(%[[T1:.+]]: {{.*}}, %[[T2:.+]]: {{.*}}, %[[T3:.+]]: {{.*}}, %[[T4:.+]]: {{.*}}):
  ^bb0(%theta1: f64, %theta2: f64, %theta3: f64, %theta4: f64):

  // CHECK: %[[X0:.+]] = "quantum.alloc"() <{pos = 0 : i32}> : () -> !quantum.qubit<1>
  %x0 = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[X1:.+]] = "quantum.H"(%[[X0]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %x1 = "quantum.H"(%x0) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  // CHECK: %[[P1:.+]] = arith.addf %[[T1]], %[[T2]] : f64
  // CHECK: %[[X2:.+]] = "quantum.Rz"(%[[X1]], %[[P1]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %x2 = "quantum.Rz"(%x1, %theta1) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NOT: "quantum.Rz"(%[[X2]], %[[T2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %x3 = "quantum.Rz"(%x2, %theta2) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: %[[X3:.+]] = "quantum.H"(%[[X2]]) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  %x4 = "quantum.H"(%x3) : (!quantum.qubit<1>) -> !quantum.qubit<1>
  // CHECK: %[[P2:.+]] = arith.addf %[[T3]], %[[T4]] : f64
  // CHECK: %[[X4:.+]] = "quantum.Rz"(%[[X3]], %[[P2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %x5 = "quantum.Rz"(%x4, %theta3) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK-NOT: "quantum.Rz"(%[[X4]], %[[T4]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %x6 = "quantum.Rz"(%x5, %theta4) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: "quantum.deallocate"(%[[X4]])
  "quantum.deallocate"(%x6) : (!quantum.qubit<1>) -> ()

  "qpu.return" () : () -> ()
}) : () -> ()
}
}

// -----

// CHECK: module {
module {
// CHECK: qpu.module @test
qpu.module @test [#qpu.target<qubits = 3, coupling = [[0, 1], [1, 2]]>] {
  // CHECK: "qpu.circuit"() <{function_type = (f64, f64) -> (), sym_name = "swap_rz"}> ({
"qpu.circuit"() <{function_type = (f64, f64) -> (), sym_name = "swap_rz"}>({
  // CHECK: ^bb0(%[[T1:.+]]: {{.*}}, %[[T2:.+]]: {{.*}}):
  ^bb0(%theta1: f64, %theta2: f64):
  // CHECK: %[[X0:.+]] = "quantum.alloc"() <{pos = 0 : i32}> : () -> !quantum.qubit<1>
  %x0 = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[Y0:.+]] = "quantum.alloc"() <{pos = 1 : i32}> : () -> !quantum.qubit<1>
  %y0 = "quantum.alloc"() : () -> !quantum.qubit<1>
  // CHECK: %[[X1:.+]], %[[Y1:.+]] = "quantum.CNOT"(%[[X0]], %[[Y0]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x1, %y1 = "quantum.CNOT"(%x0, %y0) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[P:.+]] = arith.addf %[[T1]], %[[T2]] : f64
  // CHECK: %[[Y2:.+]] = "quantum.Rz"(%[[Y1]], %[[P]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %y2 = "quantum.Rz"(%y1, %theta1) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: %[[X3:.+]], %[[Y3:.+]] = "quantum.CNOT"(%[[X1]], %[[Y2]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x3, %y3 = "quantum.CNOT"(%x1, %y2) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[X4:.+]], %[[Y4:.+]] = "quantum.SWAP"(%[[X3]], %[[Y3]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x4, %y4 = "quantum.SWAP"(%x3, %y3) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: %[[X5:.+]], %[[Y5:.+]] = "quantum.CNOT"(%[[X4]], %[[Y4]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x5, %y5 = "quantum.CNOT"(%x4, %y4) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK-NOT: "quantum.Rz"(%[[Y5]], %[[T2]]) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  %y6 = "quantum.Rz"(%y5, %theta2) : (!quantum.qubit<1>, f64) -> !quantum.qubit<1>
  // CHECK: %[[X6:.+]], %[[Y6:.+]] = "quantum.CNOT"(%[[X5]], %[[Y5]]) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  %x7, %y7 = "quantum.CNOT"(%x5, %y6) : (!quantum.qubit<1>, !quantum.qubit<1>) -> (!quantum.qubit<1>, !quantum.qubit<1>)
  // CHECK: "quantum.deallocate"(%[[X6]])
  "quantum.deallocate"(%x7) : (!quantum.qubit<1>) -> ()
  // CHECK: "quantum.deallocate"(%[[Y6]])
  "quantum.deallocate"(%y7) : (!quantum.qubit<1>) -> ()

  "qpu.return" () : () -> ()
}) : () -> ()
}
}
