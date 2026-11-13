//===- RegisterRangesAnalysis.cpp - Quantum Register Interval Anaysis ---===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

#include "quantum-mlir/Dialect/Quantum/Analysis/PhasePolynomialAnalysis.h"

#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/Interfaces/InferPhasePolynomialInterface.h"

#include "llvm/Support/Debug.h"

#include <llvm/Support/Casting.h>

#define DEBUG_TYPE "phase-polynomial-analysis"

using namespace mlir;
using namespace mlir::quantum;
using namespace mlir::quantum::dataflow;

PhasePolynomialAnalysis::PhasePolynomialAnalysis(
    DataFlowSolver &solver,
    Operation* root)
        : SparseForwardDataFlowAnalysis(solver)
{
    // Assign all identities before solving so every parity vector has the same
    // width.
    root->walk([&](AllocOp alloc) {
        allocationOffsets.try_emplace(alloc.getResult(), qubitCount);
        qubitCount += alloc.getResult().getType().getSize();
    });
}

LogicalResult PhasePolynomialAnalysis::visitOperation(
    Operation* op,
    ArrayRef<const PhasePolynomialLattice*> operands,
    ArrayRef<PhasePolynomialLattice*> results)
{
    if (auto alloc = llvm::dyn_cast<AllocOp>(op)) {
        auto it = allocationOffsets.find(alloc.getResult());
        assert(
            it != allocationOffsets.end()
            && "Allocation must belong to the analysis root");

        size_t begin = it->second;
        size_t end = begin + alloc.getResult().getType().getSize();
        llvm::SmallVector<ConstantPhasePolynomial> values;
        llvm::SmallVector<size_t> qubits;
        for (size_t i = begin; i < end; ++i) {
            ConstantPhasePolynomial polynomial(qubitCount, 0);
            polynomial.setBit(i);
            values.push_back(polynomial);
            qubits.push_back(i);
        }

        PhasePolynomial initial(values, qubits);
        propagateIfChanged(results[0], results[0]->join(initial));
        return success();
    }

    auto inferrable = llvm::dyn_cast<InferPhasePolynomialInterface>(op);
    if (!inferrable) {
        setAllToEntryStates(results);
        return success();
    }

    LLVM_DEBUG(llvm::dbgs() << "Inferring ranges for " << *op << "\n");
    auto argRanges = llvm::map_to_vector(
        operands,
        [](const PhasePolynomialLattice* lattice) {
            return lattice->getValue();
        });

    auto joinCallback = [&](Value v, const PhasePolynomial &attrs) {
        auto result = dyn_cast<OpResult>(v);
        if (!result) return;
        assert(llvm::is_contained(op->getResults(), result));

        LLVM_DEBUG(llvm::dbgs() << "Inferred range " << attrs << "\n");
        PhasePolynomialLattice* lattice = results[result.getResultNumber()];
        PhasePolynomial oldRange = lattice->getValue();

        ChangeResult changed = lattice->join(attrs);

        // Catch loop results with loop variant bounds and conservatively make
        // them [-inf, inf] so we don't circle around infinitely often (because
        // the dataflow analysis in MLIR doesn't attempt to work out trip counts
        // and often can't).
        bool isYieldedResult = llvm::any_of(v.getUsers(), [](Operation* op) {
            return op->hasTrait<OpTrait::IsTerminator>();
        });
        if (isYieldedResult && !oldRange.isUninitialized()
            && !(lattice->getValue() == oldRange)) {
            LLVM_DEBUG(llvm::dbgs() << "Loop variant loop result detected\n");
            changed |= lattice->join(PhasePolynomial());
        }
        propagateIfChanged(lattice, changed);
    };

    inferrable.inferResultPolynomial(argRanges, joinCallback);
    return success();
}
