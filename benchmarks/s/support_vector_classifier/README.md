# Support Vector Classifier

This benchmark ports the pinned Rust educational projected-gradient support vector classifier. It fits a binary model and predicts a batch with either the linear kernel or the RBF kernel. This package benchmarks that particular solver variant rather than treating all SVC implementations as interchangeable.

## Contract

The `i64_array_scalar` input is a signed 64-bit array:

    [n, d, kernel, q, labels[n], train_X row-major (n*d), test_X row-major (q*d)]

The array length must be exactly `4 + n + n*d + q*d`. Training row count `n` is 2 through 8; feature width `d` is 1 through 4; test row count `q` is 1 through 16. `kernel` is 0 for linear or 1 for RBF. Each label is exactly -1 or +1, and both classes must occur. Every feature is an integer from -4 through 4 and is converted exactly to `f64`. The adapter fixes regularization `C=1` and, for RBF, `gamma=1`.

The result is a bit mask. Bit `i` is 1 when test row `i` is classified as +1, and 0 when it is -1. The source classifies a score of exactly zero as +1. Invalid framing or values return -1 before fitting.

## Solver behavior

The source initializes every dual coefficient to 0.5 and performs at most 5,000 projected gradient iterations. Its learning rate is `0.1 / (1 + iteration / 1000)`, coefficients are projected into `[0,C]`, and ten correction passes enforce the equality constraint. It stops when the coefficient change has Euclidean norm below `1e-8`. The offset averages free support-vector residuals, falling back to all training rows when none are free. Prediction uses `sum(lambda[j] * label[j] * K(train[j], test)) + offset >= 0`.

## Workload and oracle

The workload includes linear and RBF models, several feature widths, both classes, malformed/domain cases, and the maximum frame. Valid test rows are chosen so their decision scores have clear margins and do not rely on the score-zero tie rule. The independent reference implementation is `benchmarks/support_vector_classifier_oracle.py`.

Build an implementation and its ABI checker with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm support_vector_classifier --language rust --with-checker

## Implementations

| Language | Source |
| --- | --- |
| C | `c/s/support_vector_classifier.c` |
| C3 | `c3/s/support_vector_classifier.c3` |
| C++ | `cpp/s/support_vector_classifier.cpp` |
| Elisa | `elisa/s/support_vector_classifier.elisa` |
| Nim | `nim/s/support_vector_classifier.nim` |
| Odin | `odin/s/support_vector_classifier.odin` |
| Rust | `rust/s/support_vector_classifier.rs` |
| V | `v/s/support_vector_classifier.v` |
| Zig | `zig/s/support_vector_classifier.zig` |

## Reviewed source

The pinned source is `support_vector_classifier.rs` in TheAlgorithms/Rust at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. It uses an educational projected-gradient dual solver, not a general quadratic-programming backend.
