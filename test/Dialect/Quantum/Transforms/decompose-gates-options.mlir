// RUN: not quantum-opt %s --decompose-gates='decompositions=CCX' 2>&1 | FileCheck %s --check-prefix=MALFORMED
// RUN: not quantum-opt %s --decompose-gates='decompositions=quantum.SWAP:qelib1' 2>&1 | FileCheck %s --check-prefix=GATE
// RUN: not quantum-opt %s --decompose-gates='decompositions=CCX:unknown' 2>&1 | FileCheck %s --check-prefix=METHOD
// RUN: not quantum-opt %s --decompose-gates='decompositions=quantum.CCX:qelib1,Toffoli:qelib1' 2>&1 | FileCheck %s --check-prefix=DUPLICATE

// MALFORMED: error: expected gate:method in decomposition 'CCX'
// GATE: error: unsupported decomposition gate 'quantum.SWAP'
// METHOD: error: unsupported decomposition method 'unknown' for 'CCX'; supported: qelib1
// DUPLICATE: error: duplicate decomposition for quantum.CCX
module {}
