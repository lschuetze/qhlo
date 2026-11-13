/// Implements the Gate Decomposition.
///
/// @file
/// @author     Lars Schütze (lars.schuetze@tu-dresden.de)

#include "quantum-mlir/Dialect/Quantum/IR/QuantumBase.h"
#include "quantum-mlir/Dialect/Quantum/IR/QuantumOps.h"
#include "quantum-mlir/Dialect/Quantum/Transforms/Passes.h"

#include <llvm/ADT/StringRef.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/PatternMatch.h>
#include <mlir/Transforms/GreedyPatternRewriteDriver.h>

//===- Generated includes -------------------------------------------------===//

namespace mlir::quantum {

#define GEN_PASS_DEF_DECOMPOSEGATES
#include "quantum-mlir/Dialect/Quantum/Transforms/Passes.h.inc"

} // namespace mlir::quantum

//===----------------------------------------------------------------------===//

namespace {

struct CCXQelib1Pattern : mlir::OpRewritePattern<mlir::quantum::CCXOp> {
    using OpRewritePattern::OpRewritePattern;

    mlir::LogicalResult matchAndRewrite(
        mlir::quantum::CCXOp op,
        mlir::PatternRewriter &rewriter) const override
    {
        mlir::Value a = op.getControl1();
        mlir::Value b = op.getControl2();
        mlir::Value c = op.getTarget();
        const auto loc = op.getLoc();
        auto cx = [&](mlir::Value &control, mlir::Value &target) {
            auto gate =
                mlir::quantum::CNOTOp::create(rewriter, loc, control, target);
            control = gate.getControlOut();
            target = gate.getTargetOut();
        };

        // Preserve the exact qelib1 sequence, including its global phase.
        c = mlir::quantum::HOp::create(rewriter, loc, c).getResult();
        cx(b, c);
        c = mlir::quantum::TdgOp::create(rewriter, loc, c).getResult();
        cx(a, c);
        c = mlir::quantum::TOp::create(rewriter, loc, c).getResult();
        cx(b, c);
        c = mlir::quantum::TdgOp::create(rewriter, loc, c).getResult();
        cx(a, c);
        b = mlir::quantum::TOp::create(rewriter, loc, b).getResult();
        c = mlir::quantum::TOp::create(rewriter, loc, c).getResult();
        c = mlir::quantum::HOp::create(rewriter, loc, c).getResult();
        cx(a, b);
        a = mlir::quantum::TOp::create(rewriter, loc, a).getResult();
        b = mlir::quantum::TdgOp::create(rewriter, loc, b).getResult();
        cx(a, b);

        rewriter.replaceOp(op, {a, b, c});
        return mlir::success();
    }
};

static void populateDecomposeGatesPatterns(
    mlir::RewritePatternSet &patterns,
    bool decomposeCCX)
{
    if (decomposeCCX) patterns.add<CCXQelib1Pattern>(patterns.getContext());
}

struct DecomposeGatesPass
        : mlir::quantum::impl::DecomposeGatesBase<DecomposeGatesPass> {
    using DecomposeGatesBase::DecomposeGatesBase;

    mlir::LogicalResult initialize(mlir::MLIRContext* context) override;
    void runOnOperation() override;

private:
    bool decomposeCCX = false;
};

} // namespace

mlir::LogicalResult DecomposeGatesPass::initialize(mlir::MLIRContext* context)
{
    decomposeCCX = false;
    const auto loc = mlir::UnknownLoc::get(context);
    for (const std::string &selection : decompositions) {
        const auto [gate, method] = llvm::StringRef(selection).split(':');
        if (gate.empty() || method.empty() || method.contains(':'))
            return mlir::emitError(loc)
                   << "expected gate:method in decomposition '" << selection
                   << "'";

        if (gate != mlir::quantum::CCXOp::getOperationName() && gate != "CCX"
            && gate != "Toffoli")
            return mlir::emitError(loc)
                   << "unsupported decomposition gate '" << gate
                   << "'; supported: quantum.CCX (aliases: CCX, Toffoli)";

        if (method != "qelib1")
            return mlir::emitError(loc)
                   << "unsupported decomposition method '" << method
                   << "' for '" << gate << "'; supported: qelib1";

        if (decomposeCCX)
            return mlir::emitError(loc)
                   << "duplicate decomposition for quantum.CCX";
        decomposeCCX = true;
    }
    return mlir::success();
}

void DecomposeGatesPass::runOnOperation()
{
    if (!decomposeCCX) return;

    mlir::RewritePatternSet patterns(&getContext());
    populateDecomposeGatesPatterns(patterns, decomposeCCX);
    mlir::GreedyRewriteConfig config;
    config.enableFolding(false);
    if (mlir::failed(
            mlir::applyPatternsGreedily(
                getOperation(),
                std::move(patterns),
                config)))
        signalPassFailure();
}

std::unique_ptr<mlir::Pass> mlir::quantum::createDecomposeGatesPass()
{ return std::make_unique<DecomposeGatesPass>(); }
