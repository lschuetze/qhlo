/// Implements the Herimitan trait cancelling.
///
/// @file
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)
/// @author     Washim Neupane (washimneupane@outlook.com)

#include "mlir/IR/PatternMatch.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "quantum-mlir/Dialect/Quantum/IR/Quantum.h"
#include "quantum-mlir/Dialect/Quantum/Transforms/Passes.h"

#include "llvm/ADT/STLExtras.h"

using namespace mlir;
using namespace mlir::quantum;

//===- Generated includes -------------------------------------------------===//

namespace mlir::quantum {

#define GEN_PASS_DEF_HERMITIANCANCEL
#include "quantum-mlir/Dialect/Quantum/Transforms/Passes.h.inc"

} // namespace mlir::quantum

//===----------------------------------------------------------------------===//

namespace {

struct HermitianCancelPass
        : quantum::impl::HermitianCancelBase<HermitianCancelPass> {
    using HermitianCancelBase::HermitianCancelBase;

    void runOnOperation() override;
};

/// Pattern: Cancel double Hermitian ops
struct FoldDoubleHermitian : OpTraitRewritePattern<Hermitian> {
    using OpTraitRewritePattern::OpTraitRewritePattern;

    LogicalResult
    matchAndRewrite(Operation* op, PatternRewriter &rewriter) const override
    {
        if (op->getNumOperands() == 0) return failure();

        auto inner = op->getOperand(0).getDefiningOp();
        if (!inner || inner->getName() != op->getName()) return failure();

        // Cancellation requires the same gate instance and wire ordering.
        if (!llvm::equal(op->getOperands(), inner->getResults()))
            return failure();

        rewriter.replaceOp(op, inner->getOperands());
        return success();
    }
};

} // namespace

void HermitianCancelPass::runOnOperation()
{
    RewritePatternSet patterns(&getContext());
    populateHermitianCancelPatterns(patterns);
    // Use the pattern's wiring checks instead of the Hermitian trait folder.
    GreedyRewriteConfig config;
    config.enableFolding(false);
    if (failed(
            applyPatternsGreedily(getOperation(), std::move(patterns), config)))
        signalPassFailure();
}

void mlir::quantum::populateHermitianCancelPatterns(RewritePatternSet &patterns)
{ patterns.add<FoldDoubleHermitian>(patterns.getContext()); }

std::unique_ptr<Pass> mlir::quantum::createHermitianCancelPass()
{ return std::make_unique<HermitianCancelPass>(); }
