# Softmax

This bounded benchmark covers one-dimensional softmax from the pinned JavaScript, Python, and Rust implementations. The pinned MATLAB file is a fixed-grid plotting script rather than a vector function and is excluded as `excluded_non_benchmarkable`.

## Contract

The input is a nonempty vector of 1 to 64 finite float64 logits, each in `[-20, 20]`. The output has the same length and contains the normalized exponential probability for each logit. Invalid length, non-finite values, or out-of-range logits return `-1`. For a valid input, a null output pointer or capacity smaller than the input length returns `-2` without writing output.

The independent oracle uses max-shifted double-precision exponentials. The JavaScript implementation directly exponentiates each input, the Python implementation uses max subtraction, and the Rust implementation uses f32 exponentials and summation. The bounded domain keeps the direct exponentials finite and nonzero and keeps Rust's f32 results within the shared relative tolerance. The comparison uses absolute tolerance `0` and relative tolerance `1e-5`.

See [`workload.json`](workload.json), the [oracle](../../softmax_oracle.py), and the pinned [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Softmax.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/softmax.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/softmax.rs) sources.

| Language | Port |
|---|---|
| C | [`c/s/softmax.c`](../../../c/s/softmax.c) |
| C3 | [`c3/s/softmax.c3`](../../../c3/s/softmax.c3) |
| C++ | [`cpp/s/softmax.cpp`](../../../cpp/s/softmax.cpp) |
| Elisa | [`elisa/s/softmax.elisa`](../../../elisa/s/softmax.elisa) |
| Nim | [`nim/s/softmax.nim`](../../../nim/s/softmax.nim) |
| Odin | [`odin/s/softmax.odin`](../../../odin/s/softmax.odin) |
| Rust | [`rust/s/softmax.rs`](../../../rust/s/softmax.rs) |
| V | [`v/s/softmax.v`](../../../v/s/softmax.v) |
| Zig | [`zig/s/softmax.zig`](../../../zig/s/softmax.zig) |

The focused verifier is `python3 benchmarks/verify_float64_slice_io.py --algorithm softmax`.
