//===- Passes.td - Quantum dialect passes ---------------------*- tablegen -*-===//
//
// This is the definitions file for the Quantum dialect transform passes.
//
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_PASSES
#define QUANTUM_PASSES

include "mlir/Pass/PassBase.td"

def EliminatePhaseBeforeMeasurement : Pass<"quantum-eliminate-phase-before-measurement", "ModuleOp"> {
  let summary = "Eliminate phase gates immediately before measurement";

  let description = [{
  }];

  let constructor = "mlir::quantum::createEliminatePhaseBeforeMeasurementPass()";
}

def HermitianCancel : Pass<"hermitian-cancel", "ModuleOp"> {
  let summary = "Hermitian Cancellation on the `quantum` dialect";

  let description = [{
  }];

  let constructor = "mlir::quantum::createHermitianCancelPass()";
}

def PhasePolynomialMerge : Pass<"phase-poly-merge", "ModuleOp"> {
  let summary = "Rotation gate merging based on phase polynomial analysis.";
  
  let description = [{
  }];

  let constructor = "mlir::quantum::createPhasePolynomialMergePass()";
}

def VerifyLinearity : Pass<"verify-linearity", "ModuleOp"> {
  let summary = "Check linearity of qubit-consuming operations.";

  let description = [{
  }];

  let constructor = "mlir::quantum::createVerifyLinearityPass()";
}

#endif // QUANTUM_PASSES
