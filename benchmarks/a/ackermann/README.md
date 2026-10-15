# Ackermann Function

Compute the classic two-argument Ackermann function using its recursive definition:

- A(0, n) = n + 1
- A(m, 0) = A(m - 1, 1) for m > 0
- A(m, n) = A(m - 1, A(m, n - 1)) for m > 0 and n > 0

## Contract

- Inputs are two signed 64-bit integers (m, n).
- The supported domain is 0 <= m <= 3 and 0 <= n <= 5.
- Inputs outside that domain return -1.
- The largest supported result is A(3, 5) = 253.
- Implementations use direct recursion, preserving the algorithm's characteristic growth.

The bound avoids unbounded recursion and keeps results within the signed 64-bit ABI. It is an explicit benchmark domain, not a general-purpose limit for all implementations of Ackermann.

## Workload and verification

[workload.json](workload.json) covers all 24 supported input pairs and signed-boundary and domain-invalid inputs. [verify_binary_scalar.py](../../verify_binary_scalar.py) checks each language against an independently implemented recursive oracle and validates every workload record through the recorder. All nine ports passed on the native host.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/a/ackermann.c](../../../c/a/ackermann.c) |
| C3 | [c3/a/ackermann.c3](../../../c3/a/ackermann.c3) |
| C++ | [cpp/a/ackermann.cpp](../../../cpp/a/ackermann.cpp) |
| Elisa | [elisa/a/ackermann.elisa](../../../elisa/a/ackermann.elisa) |
| Nim | [nim/a/ackermann.nim](../../../nim/a/ackermann.nim) |
| Odin | [odin/a/ackermann.odin](../../../odin/a/ackermann.odin) |
| Rust | [rust/a/ackermann.rs](../../../rust/a/ackermann.rs) |
| V | [v/a/ackermann.v](../../../v/a/ackermann.v) |
| Zig | [zig/a/ackermann.zig](../../../zig/a/ackermann.zig) |

## TheAlgorithms reference

- [Dart recursive Ackermann implementation](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/ackermann.dart) documents the recursive cases and warns that large arguments quickly exceed practical recursion limits.
