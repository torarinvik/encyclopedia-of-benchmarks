# ADALINE learning

This benchmark follows the pinned TheAlgorithms C and C++ implementations' sequential training update: start every weight and the bias at 1, predict with the sign threshold (`score > 0` gives `+1`, otherwise `-1`), then update weights using `eta * (label - prediction) * feature`. The source demo also creates random datasets and waits for terminal input; this benchmark uses a fixed dataset and calls only the learning algorithm. The second C++ repository contains the same implementation.

Sources: [pinned C implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/machine_learning/adaline_learning.c), [pinned C++ implementation](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/machine_learning/adaline_learning.cpp), and [duplicate C++ repository implementation](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/machine_learning/adaline_learning.cpp).

## Contract

Input is a signed-i64 array encoded as `[sample_count, feature_count, eta_numerator, eta_shift, max_iterations, then sample rows]`. Each row has `feature_count` integer features followed by a label. There must be 1–32 samples, 1–8 features, feature values in `[-16, 16]`, labels of `-1` or `1`, a learning rate `eta_numerator / 2^eta_shift` strictly between 0 and 1, `eta_shift` from 1 to 12, and a maximum of 1–500 iterations.

The source initializes all weights and the bias to 1 and updates samples in input order. Training stops after an epoch with no mistakes or at the iteration limit. Under these bounds, the source's average-correction threshold of `1e-5` is reached exactly when an epoch has no mistakes. The ports keep the same updates in exact fixed-point integer arithmetic, with weights scaled by `2^eta_shift`.

Output is little-endian signed-i32 values: `[completed_epochs, scaled_weight_0, ..., scaled_weight_(feature_count-1), scaled_bias, final_prediction_0, ..., final_prediction_(sample_count-1)]`. The function returns the output byte count, `-1` for malformed input, or `-2` when the output buffer is too small.

The workload includes the pinned C demo's fixed ten-row dataset, convergence, iteration-limit, and malformed-input cases. Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`; run the independent cross-language verifier with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm adaline_learning --languages rust
```
