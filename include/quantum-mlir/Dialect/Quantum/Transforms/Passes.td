//===- Passes.td - Quantum dialect passes ---------------------*- tablegen -*-===//
//
// This is the definitions file for the Quantum dialect transform passes.
//
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_PASSES
#define QUANTUM_PASSES

include "mlir/Pass/PassBase.td"

def EliminatePhaseBeforeMeasurement
    : Pass<"quantum-eliminate-phase-before-measurement", "mlir::ModuleOp"> {
  let summary = "Eliminate phase gates immediately before measurement";

  let description = [{
  }];

  let constructor = "mlir::quantum::createEliminatePhaseBeforeMeasurementPass()";
}

def HermitianCancel : Pass<"quantum-hermitian-cancel", "mlir::ModuleOp"> {
  let summary = "Hermitian Cancellation on the `quantum` dialect";

  let description = [{
  }];

  let constructor = "mlir::quantum::createHermitianCancelPass()";
}

def PhasePolynomialMerge : Pass<"quantum-phase-poly-merge", "mlir::ModuleOp"> {
  let summary = "Rotation gate merging based on phase polynomial analysis.";

  let description = [{
  }];

  let constructor = "mlir::quantum::createPhasePolynomialMergePass()";

  let dependentDialects = [
    "mlir::arith::ArithDialect",
    "mlir::quantum::QuantumDialect"
  ];
}

def VerifyLinearity : Pass<"quantum-verify-linearity", "mlir::ModuleOp"> {
  let summary = "Check linearity of qubit-consuming operations.";

  let description = [{
  }];

  let constructor = "mlir::quantum::createVerifyLinearityPass()";
}

def DecomposeGates : Pass<"quantum-decompose-gates", "mlir::ModuleOp"> {
  let summary = "Decompose selected gates using named methods";

  let description = [{
    Select decompositions using comma-separated gate:method pairs, for example
    `decompositions=quantum.CCX:qelib1`. The `qelib1` method implements the exact
    OpenQASM 2 standard library Toffoli decomposition into H, CNOT, T and Tdg
    gates, without ancillas. `CCX` and `Toffoli` are accepted as gate aliases.
    An empty selection leaves the IR unchanged. Unknown gates, unsupported
    methods and duplicate gate selections are errors.
  }];

  let constructor = "mlir::quantum::createDecomposeGatesPass()";

  let dependentDialects = ["mlir::quantum::QuantumDialect"];

  let options = [
    ListOption<"decompositions", "decompositions", "std::string",
               "Gate:method pairs; supported: quantum.CCX:qelib1 "
               "(aliases: CCX, Toffoli)">
  ];
}

#endif // QUANTUM_PASSES
