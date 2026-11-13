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

def DecomposeGates : Pass<"decompose-gates", "ModuleOp"> {
  let summary = "Decompose selected gates using named methods";

  let description = [{
    Select decompositions using comma-separated gate:method pairs, for example
    `decompositions=quantum.CCX:qelib1`. The `qelib1` method implements the exact
    OpenQASM 2 standard library Toffoli decomposition into H, CNOT, T and Tdg
    gates, without ancillas. `CCX` and `Toffoli` are accepted as gate aliases.
    An empty selection leaves the IR unchanged. Unknown gates, unsupported
    methods and duplicate gate selections are errors.
  }];

  let options = [
    ListOption<"decompositions", "decompositions", "std::string",
               "Gate:method pairs; supported: quantum.CCX:qelib1 (aliases: CCX, Toffoli)">
  ];

  let dependentDialects = ["mlir::quantum::QuantumDialect"];

  let constructor = "mlir::quantum::createDecomposeGatesPass()";
}

#endif // QUANTUM_PASSES
