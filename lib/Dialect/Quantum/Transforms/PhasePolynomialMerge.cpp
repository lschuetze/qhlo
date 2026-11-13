/// Implements rotation gate angel merge based on phase polynomial analysis.
///
/// @file
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)

#include "quantum-mlir/Dialect/QPU/IR/QPUOps.h"
#include "quantum-mlir/Dialect/Quantum/Analysis/PhasePolynomialAnalysis.h"
#include "quantum-mlir/Dialect/Quantum/IR/Quantum.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumTypes.h"
#include "quantum-mlir/Dialect/Quantum/Interfaces/InferPhasePolynomialInterface.h"
#include "quantum-mlir/Dialect/Quantum/Transforms/Passes.h"

#include <llvm/ADT/MapVector.h>
#include <llvm/ADT/STLExtras.h>
#include <llvm/Support/Debug.h>
#include <mlir/Analysis/DataFlow/ConstantPropagationAnalysis.h>
#include <mlir/Analysis/DataFlow/DeadCodeAnalysis.h>
#include <mlir/Analysis/DataFlow/SparseAnalysis.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinOps.h>
#include <mlir/IR/Dominance.h>
#include <mlir/Pass/Pass.h>
#include <utility>

#define DEBUG_TYPE "quantum-phase-poly-merge"

using namespace mlir;
using namespace mlir::quantum;
using namespace mlir::quantum::dataflow;

//===- Generated includes -------------------------------------------------===//

namespace mlir::quantum {

#define GEN_PASS_DEF_PHASEPOLYNOMIALMERGE
#include "quantum-mlir/Dialect/Quantum/Transforms/Passes.h.inc"

} // namespace mlir::quantum

//===----------------------------------------------------------------------===//

namespace {

struct PhasePolynomialMergePass
        : quantum::impl::PhasePolynomialMergeBase<PhasePolynomialMergePass> {
    using PhasePolynomialMergeBase::PhasePolynomialMergeBase;

    void runOnOperation() override;
};

static Value buildSum(ArrayRef<Value> thetas, OpBuilder &builder, Location loc)
{
    assert(!thetas.empty() && "Cannot build an empty angle sum");
    if (thetas.size() == 1) return thetas[0];

    SmallVector<Value> next;
    for (size_t i = 0; i < thetas.size(); i += 2) {
        if (i + 1 < thetas.size()) {
            next.push_back(builder.createOrFold<arith::AddFOp>(
                loc,
                thetas[i].getType(),
                thetas[i],
                thetas[i + 1]));
        } else {
            next.push_back(thetas[i]);
        }
    }
    return buildSum(next, builder, loc);
}

// Equal parity is a candidate for merging, not a proof of execution
// compatibility.
struct RotationGroup {
    explicit RotationGroup(RzOp rotation) : rotations{rotation} {}

    bool tryAppend(RzOp rotation, const DominanceInfo &dominance)
    {
        RzOp first = rotations.front();
        if (rotation->getBlock() != first->getBlock()
            || !rotations.back()->isBeforeInBlock(rotation)
            || rotation.getTheta().getType() != first.getTheta().getType()
            || !dominance.properlyDominates(rotation.getTheta(), first))
            return false;

        rotations.push_back(rotation);
        return true;
    }

    void merge()
    {
        if (rotations.size() < 2) return;

        RzOp first = rotations.front();
        OpBuilder builder(first);
        auto thetas = llvm::map_to_vector(
            rotations,
            [](RzOp rotation) -> Value { return rotation.getTheta(); });
        Value theta = buildSum(thetas, builder, first.getLoc());
        RzOp merged =
            RzOp::create(builder, first.getLoc(), first.getInput(), theta);

        first.getResult().replaceAllUsesWith(merged.getResult());
        for (RzOp rotation : rotations) {
            rotation.getResult().replaceAllUsesWith(rotation.getInput());
            rotation->erase();
        }
        rotations.clear();
    }

private:
    SmallVector<RzOp> rotations;
};

struct RotationGroups {
    void collect(
        RzOp rotation,
        ArrayRef<ConstantPhasePolynomial> polynomial,
        const DominanceInfo &dominance)
    {
        auto &candidates = groups[{
            rotation->getBlock(),
            SmallVector<ConstantPhasePolynomial>(polynomial)}];
        // A later angle may be unavailable at an earlier group's insertion
        // point. Keep separate groups so subsequent rotations can still merge.
        for (RotationGroup &group : candidates)
            if (group.tryAppend(rotation, dominance)) return;
        candidates.emplace_back(rotation);
    }

    void merge()
    {
        for (auto &[key, candidates] : groups)
            for (RotationGroup &group : candidates) group.merge();
        groups.clear();
    }

private:
    using Key = std::pair<Block*, SmallVector<ConstantPhasePolynomial>>;
    // Preserve collection order to make the rewrite deterministic.
    llvm::MapVector<Key, SmallVector<RotationGroup>> groups;
};

} // namespace

void PhasePolynomialMergePass::runOnOperation()
{
    // Each qpu::circuit is the root of a quantum circuit
    // Run analysis on each circuit and collect operations with same-valued
    // epochs and parity bits
    getOperation().walk([&](qpu::CircuitOp circOp) {
        mlir::DataFlowSolver solver;
        solver.load<mlir::dataflow::DeadCodeAnalysis>();
        solver.load<mlir::dataflow::SparseConstantPropagation>();
        solver.load<quantum::dataflow::PhasePolynomialAnalysis>(
            circOp.getOperation());

        DominanceInfo dominance(circOp);
        RotationGroups groups;

        if (failed(solver.initializeAndRun(circOp))) return signalPassFailure();

        LLVM_DEBUG(
            llvm::dbgs() << "[PhasePolyMerge]: Collect groups for circuit: "
                         << circOp.getSymName() << "\n");

        circOp->walk([&](RzOp rzop) {
            const PhasePolynomialLattice* lattice =
                solver.lookupState<PhasePolynomialLattice>(rzop.getInput());
            // Unreachable operations and unknown inputs cannot justify a merge.
            if (!lattice || lattice->getValue().isUninitialized()) return;

            LLVM_DEBUG(
                llvm::dbgs() << "[PhasePolyMerge]: Collect "
                             << lattice->getValue() << " for " << rzop << "\n");

            groups.collect(rzop, lattice->getValue().getValue(), dominance);
        });

        groups.merge();
    });
}

std::unique_ptr<Pass> mlir::quantum::createPhasePolynomialMergePass()
{ return std::make_unique<PhasePolynomialMergePass>(); }
