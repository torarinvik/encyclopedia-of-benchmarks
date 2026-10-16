# Symmetric derivative

## Contract

The pinned Dart routine estimates a derivative by the centered quotient (f(x+h) - f(x-h)) / (2*h), with default h=1e-10. The benchmark fixes h to that default and bounds the callback family to the source main's two examples: sin and exp.

Input is exactly [function_id, x_nanounits]. Function id 0 selects sin and 1 selects exp; x is x_nanounits / 1e9, with x_nanounits in [-6300000000, 6300000000]. Output is the binary64 centered quotient. Invalid input returns -1e300. The benchmark uses absolute tolerance 1e-3 and relative tolerance 1e-6 for libm and finite-difference rounding.

## Workload

workload.json covers both functions at zero and both endpoints, plus the pinned sin(pi), sin(2*pi), and exp(3) examples represented on the nanounit input grid. It also covers positive/negative interior values and malformed or out-of-domain inputs. The source-derived oracle is ../../symmetric_derivative_oracle.py.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/symmetric_derivative.c](../../../c/s/symmetric_derivative.c) |
| C3 | [c3/s/symmetric_derivative.c3](../../../c3/s/symmetric_derivative.c3) |
| C++ | [cpp/s/symmetric_derivative.cpp](../../../cpp/s/symmetric_derivative.cpp) |
| Elisa | [elisa/s/symmetric_derivative.elisa](../../../elisa/s/symmetric_derivative.elisa) |
| Nim | [nim/s/symmetric_derivative.nim](../../../nim/s/symmetric_derivative.nim) |
| Odin | [odin/s/symmetric_derivative.odin](../../../odin/s/symmetric_derivative.odin) |
| Rust | [rust/s/symmetric_derivative.rs](../../../rust/s/symmetric_derivative.rs) |
| V | [v/s/symmetric_derivative.v](../../../v/s/symmetric_derivative.v) |
| Zig | [zig/s/symmetric_derivative.zig](../../../zig/s/symmetric_derivative.zig) |

## Pinned source

[Dart symmetric_derivative.dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/symmetric_derivative.dart)
