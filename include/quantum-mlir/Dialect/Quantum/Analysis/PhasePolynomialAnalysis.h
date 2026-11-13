//===--- PhasePolynomialAnalysis.h - Quantum Phase Poly Anaysis --*- C++-*-===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#ifndef QUANTUM_MLIR_ANALYSIS_DATAFLOW_PHASEPOLYNOMIALANALYSIS_H
#define QUANTUM_MLIR_ANALYSIS_DATAFLOW_PHASEPOLYNOMIALANALYSIS_H

#include "quantum-mlir/Dialect/Quantum/Interfaces/InferPhasePolynomialInterface.h"

#include <llvm/ADT/DenseMap.h>
#include <mlir/Analysis/DataFlow/SparseAnalysis.h>
#include <mlir/Analysis/DataFlowFramework.h>
#include <mlir/Interfaces/ControlFlowInterfaces.h>

namespace mlir {

namespace quantum {
namespace dataflow {

//===----------------------------------------------------------------------===//
// PhasePolynomialLattice
//===----------------------------------------------------------------------===//
class PhasePolynomialLattice : public mlir::dataflow::Lattice<PhasePolynomial> {
public:
    using mlir::dataflow::Lattice<PhasePolynomial>::Lattice;
};

//===----------------------------------------------------------------------===//
// PhasePolynomialAnalysis
//===----------------------------------------------------------------------===//
class PhasePolynomialAnalysis
        : public mlir::dataflow::SparseForwardDataFlowAnalysis<
              PhasePolynomialLattice> {
public:
    PhasePolynomialAnalysis(DataFlowSolver &solver, Operation* root);

    /// At an entry point, we cannot reason about phase polynomials.
    void setToEntryState(PhasePolynomialLattice* lattice) override
    { propagateIfChanged(lattice, lattice->join(PhasePolynomial())); }

    /// Initialize allocations or invoke the operation's polynomial transfer
    /// function.
    LogicalResult visitOperation(
        Operation* op,
        ArrayRef<const PhasePolynomialLattice*> operands,
        ArrayRef<PhasePolynomialLattice*> results) override;

private:
    // Symbolic qubit identities belong to this analysis, not physical
    // placement.
    llvm::DenseMap<Value, size_t> allocationOffsets;
    size_t qubitCount = 0;
};
} // namespace dataflow
} // namespace quantum

} // namespace mlir

#endif // QUANTUM_MLIR_ANALYSIS_DATAFLOW_PHASEPOLYNOMIALANALYSIS_H
