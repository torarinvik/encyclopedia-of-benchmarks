# Forward Euler method

This benchmark ports the common forward Euler loop from the pinned C#, Java, JavaScript, and Python sources. Each step computes `y_next = y + h * f(x, y)` from the previous point and advances `x` by `h`.

## Contract

Input is `[x_start_integer, y_start_integer, step_denominator_power, step_count]`. The initial coordinates are in `[-8, 8]`, the denominator power is 1..4, and the step count is 1..16. The fixed step is `h = 2^(-step_denominator_power)` and the fixed derivative is `f(x,y)=x+y`. Thus `x_end = x_start + step_count*h`.

The output is the sequence `y_0..y_n` as little-endian binary64 values, including the initial value. The function returns the output byte count. The dyadic step grid and integer count make the C#, Java, and JavaScript `while (x < xEnd)` loops and the Python `ceil((xEnd-xStart)/h)` loop execute the same number of steps. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing.

[`workload.json`](workload.json) covers four step sizes/counts, positive and negative starting values, malformed bounds and lengths, and capacity handling.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm euler_method --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/e/euler_method/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/euler_method.c`](../../../c/e/euler_method.c) |
| C3 | [`c3/e/euler_method.c3`](../../../c3/e/euler_method.c3) |
| C++ | [`cpp/e/euler_method.cpp`](../../../cpp/e/euler_method.cpp) |
| Elisa | [`elisa/e/euler_method.elisa`](../../../elisa/e/euler_method.elisa) |
| Nim | [`nim/e/euler_method.nim`](../../../nim/e/euler_method.nim) |
| Odin | [`odin/e/euler_method.odin`](../../../odin/e/euler_method.odin) |
| Rust | [`rust/e/euler_method.rs`](../../../rust/e/euler_method.rs) |
| V | [`v/e/euler_method.v`](../../../v/e/euler_method.v) |
| Zig | [`zig/e/euler_method.zig`](../../../zig/e/euler_method.zig) |

## Pinned sources

- C# [`EulerMethod.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/EulerMethod.cs)
- Java [`EulerMethod.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/EulerMethod.java)
- JavaScript [`EulerMethod.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/EulerMethod.js)
- Python [`euler_method.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/euler_method.py)
