# Sigmoid without inbuilt function

This benchmark preserves the parameterized sigmoid defined in the pinned MATLAB script. The source reads a slope parameter a and defines y(x) = 1 / (1 + exp(-a*x)) using elementwise operations.

## Contract

The float64_pair ABI passes [x, a] as two binary64 arguments, in that order. Both values must be finite and lie in [-10, 10]. The output is the binary64 value 1 / (1 + exp(-a*x)); invalid inputs return -1e300. The input-scaled tolerance is 1e-12.

The MATLAB script plots a vector of x values, but the benchmark evaluates one scalar x per call. The caller-provided slope is part of the algorithm contract: slope zero returns 0.5, and negative slopes reverse the curve. This differs from the existing sigmoid benchmark, which fixes the slope at one and accepts only x.

## Pinned source

[Pinned MATLAB-Octave Sigmoid(without inbuilt).m](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Activation%20Functions/Sigmoid%28without%20inbuilt%29.m) at commit e150b77ad256de46c1ce3815c3d7945ac4fc28dc.

The published fixtures are in [workload.json](workload.json).

## Build and record

After the shared float64-pair runner registers this algorithm:

    python3 benchmarks/build_abi.py --family float64_pair --algorithm sigmoid_without_inbuilt --language c
    python3 benchmarks/run_float64_pair.py --algorithm sigmoid_without_inbuilt

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/sigmoid_without_inbuilt.c](../../../c/s/sigmoid_without_inbuilt.c) |
| C3 | [c3/s/sigmoid_without_inbuilt.c3](../../../c3/s/sigmoid_without_inbuilt.c3) |
| C++ | [cpp/s/sigmoid_without_inbuilt.cpp](../../../cpp/s/sigmoid_without_inbuilt.cpp) |
| Elisa | [elisa/s/sigmoid_without_inbuilt.elisa](../../../elisa/s/sigmoid_without_inbuilt.elisa) |
| Nim | [nim/s/sigmoid_without_inbuilt.nim](../../../nim/s/sigmoid_without_inbuilt.nim) |
| Odin | [odin/s/sigmoid_without_inbuilt.odin](../../../odin/s/sigmoid_without_inbuilt.odin) |
| Rust | [rust/s/sigmoid_without_inbuilt.rs](../../../rust/s/sigmoid_without_inbuilt.rs) |
| V | [v/s/sigmoid_without_inbuilt.v](../../../v/s/sigmoid_without_inbuilt.v) |
| Zig | [zig/s/sigmoid_without_inbuilt.zig](../../../zig/s/sigmoid_without_inbuilt.zig) |

