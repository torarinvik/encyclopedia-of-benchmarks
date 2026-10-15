# Median

The median is the middle value after ordering a nonempty input; for even lengths it is the arithmetic mean of the two middle values. The pinned TheAlgorithms candidates are C `numerical_methods/median.c`, Go `math/median.go`, Java and Kotlin `Median`, Lua `src/math/median.lua`, and PHP `Maths/Median.php`. Their APIs differ: the C example generates random data and integer-divides the middle pair; Go truncates integer division for integer inputs before converting to `float64`; Java and Kotlin add the middle `int` values before converting, which can overflow; Lua uses quickselect; and PHP sorts variadic numeric inputs. The catalog links every pinned file.

## Contract

- Input is a read-only array of 1 through 1,024 signed 32-bit integers.
- Implementations copy the input and insertion-sort that local copy. The caller's array is unchanged.
- The return value is exactly twice the statistical median: for odd lengths this is twice the middle value; for even lengths it is the sum of the two middle values. This integer encoding preserves `.5` results without floating-point rounding.
- All outputs fit in signed 64-bit because each input value is signed 32-bit.

The ports use the same bounded insertion-sort baseline in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. They use only portable integer operations and do not depend on processor-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers odd and even lengths, negative half-integer medians, duplicates, sorted and reverse-sorted arrays, deterministic random values, signed 32-bit boundaries, and the maximum 1,024-element input. [`benchmarks/verify_median.py`](../../verify_median.py) compares each port with an independent Python sorting oracle, then checks the benchmark recorder against every published workload case.

## Upstream sources

- [TheAlgorithms/C median.c](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/median.c)
- [TheAlgorithms/Go median.go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/median.go)
- [TheAlgorithms/Java Median.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Median.java)
- [TheAlgorithms/Kotlin Median.kt](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/math/Median.kt)
- [TheAlgorithms/Lua median.lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/median.lua)
- [TheAlgorithms/PHP Median.php](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/Median.php)
