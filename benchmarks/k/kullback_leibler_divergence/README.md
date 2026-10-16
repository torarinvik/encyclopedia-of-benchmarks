# Kullback-Leibler divergence

This package ports the pinned Python method in machine_learning/loss_functions.py. It removes entries whose target probability is zero, computes target * ln(target / prediction) for every remaining entry, and returns the sum in input order. It does not clip predictions with an epsilon, normalize either vector, or average the terms.

## Contract

The i64_array_float64_call ABI receives [n, target_0, ..., target_(n-1), prediction_0, ..., prediction_(n-1)]. There must be 1 through 64 entries and exactly 1 + 2*n signed integers. Each target and prediction integer is divided by 1,000,000 and must be in [0, 1,000,000]. The source does not require either vector to sum to 1, so the benchmark does not impose that condition.

Every prediction corresponding to a nonzero target must be positive. Predictions may be zero where the target is zero because those terms are omitted. An all-zero target vector is valid and returns 0. Invalid layouts or values return -1e300. Valid results use absolute and relative tolerance 1e-12.

The source pin is TheAlgorithms/Python, commit e1a2a8b016001309a73d5fec4818c35cca139795, path machine_learning/loss_functions.py. See the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py), [workload](workload.json), and [independent oracle](../../kullback_leibler_divergence_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/k/kullback_leibler_divergence.c |
| C3 | ../../../c3/k/kullback_leibler_divergence.c3 |
| C++ | ../../../cpp/k/kullback_leibler_divergence.cpp |
| Elisa | ../../../elisa/k/kullback_leibler_divergence.elisa |
| Nim | ../../../nim/k/kullback_leibler_divergence.nim |
| Odin | ../../../odin/k/kullback_leibler_divergence.odin |
| Rust | ../../../rust/k/kullback_leibler_divergence.rs |
| V | ../../../v/k/kullback_leibler_divergence.v |
| Zig | ../../../zig/k/kullback_leibler_divergence.zig |

Build and record with the shared i64_array_float64 ABI after its serialized dispatcher integration is complete:

python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm kullback_leibler_divergence --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm kullback_leibler_divergence
