# Open knight tour

The pinned C# and Dart implementations scan candidate starting squares in row-major order, then run recursive depth-first search with the same move order: `(+1,+2), (-1,+2), (+1,-2), (-1,-2), (+2,+1), (+2,-1), (-2,+1), (-2,-1)`. A successful board records visit numbers from 1 through `n*n`.

## Contract

- The ABI is `i64_array_bytes_output`. Input is exactly `[n]`; the shared benchmark accepts only dimensions `1` and `5`.
- No tour exists for dimensions 2–4. Dart returns an all-zero board for those dimensions, while C# throws an `ArgumentException`. The benchmark rejects those dimensions as invalid so both language ports return the same ABI result.
- Output is the row-major board as little-endian signed-i32 values. The 1×1 result is 4 bytes and the 5×5 result is 100 bytes. Invalid or null input returns `-1` before output-buffer checks; a null output pointer or insufficient capacity returns `-2` without writes.

The workload is [workload.json](workload.json), and the independent backtracking oracle is [benchmarks/open_knight_tour_oracle.py](../../open_knight_tour_oracle.py).

Pinned sources: [TheAlgorithms/C-Sharp `OpenKnightTour.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Problems/KnightTour/OpenKnightTour.cs) and [TheAlgorithms/Dart `open_knight_tour.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/backtracking/open_knight_tour.dart).

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm open_knight_tour --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm open_knight_tour
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm open_knight_tour --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/n/open_knight_tour.c](../../../c/n/open_knight_tour.c) |
| C3 | [c3/n/open_knight_tour.c3](../../../c3/n/open_knight_tour.c3) |
| C++ | [cpp/n/open_knight_tour.cpp](../../../cpp/n/open_knight_tour.cpp) |
| Elisa | [elisa/n/open_knight_tour.elisa](../../../elisa/n/open_knight_tour.elisa) |
| Nim | [nim/n/open_knight_tour.nim](../../../nim/n/open_knight_tour.nim) |
| Odin | [odin/n/open_knight_tour.odin](../../../odin/n/open_knight_tour.odin) |
| Rust | [rust/n/open_knight_tour.rs](../../../rust/n/open_knight_tour.rs) |
| V | [v/n/open_knight_tour.v](../../../v/n/open_knight_tour.v) |
| Zig | [zig/n/open_knight_tour.zig](../../../zig/n/open_knight_tour.zig) |
