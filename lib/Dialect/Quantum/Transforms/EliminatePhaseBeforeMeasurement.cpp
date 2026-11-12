/// Eliminates phase gates immediately before measurement.
///
/// @file
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)
/// @author     Washim Neupane (washimneupane@outlook.com)

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "quantum-mlir/Dialect/Quantum/IR/Quantum.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"

using namespace mlir;
using namespace mlir::quantum;

//===- Generated includes -------------------------------------------------===//

namespace mlir::quantum {

#define GEN_PASS_DEF_ELIMINATEPHASEBEFOREMEASUREMENT
#include "quantum-mlir/Dialect/Quantum/Transforms/Passes.h.inc"

} // namespace mlir::quantum

//===----------------------------------------------------------------------===//

namespace {

struct EliminatePhaseBeforeMeasurementPass
        : mlir::quantum::impl::EliminatePhaseBeforeMeasurementBase<
              EliminatePhaseBeforeMeasurementPass> {
    using EliminatePhaseBeforeMeasurementBase::
        EliminatePhaseBeforeMeasurementBase;

    void runOnOperation() override;
};

/// Pattern: Drop phase gates immediately before measurement
template<typename PhaseOp>
struct EliminatePhaseBeforeMeasurement : OpRewritePattern<PhaseOp> {
    using OpRewritePattern<PhaseOp>::OpRewritePattern;

    LogicalResult
    matchAndRewrite(PhaseOp op, PatternRewriter &rewriter) const override
    {
        auto userOp = *op.getResult().getUsers().begin();
        if (dyn_cast<MeasureOp>(userOp)) {
            rewriter.replaceOp(op, op.getOperand());
            return success();
        }
        return failure();
    }
};

} // namespace

void EliminatePhaseBeforeMeasurementPass::runOnOperation()
{
    RewritePatternSet patterns(&getContext());
    populateEliminatePhaseBeforeMeasurementPatterns(patterns);
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
        signalPassFailure();
}

void mlir::quantum::populateEliminatePhaseBeforeMeasurementPatterns(
    RewritePatternSet &patterns)
{
    patterns.add<
        EliminatePhaseBeforeMeasurement<ZOp>,
        EliminatePhaseBeforeMeasurement<SOp>,
        EliminatePhaseBeforeMeasurement<TOp>,
        EliminatePhaseBeforeMeasurement<SdgOp>,
        EliminatePhaseBeforeMeasurement<TdgOp>>(patterns.getContext());
}

std::unique_ptr<Pass> mlir::quantum::createEliminatePhaseBeforeMeasurementPass()
{ return std::make_unique<EliminatePhaseBeforeMeasurementPass>(); }
