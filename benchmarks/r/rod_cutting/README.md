# Rod cutting

Given a price for each integral piece length, return the maximum revenue obtainable by cutting a rod into one or more pieces. The canonical implementation follows the pinned bottom-up C++ routine: for each rod length `i`, try first cuts `j=1..i` and compute `profit[i] = max(price[j-1] + profit[i-j])`, starting with `profit[0]=0`. It returns only the best value, so which cut sequence wins a tie is not observable.

## Contract

The `i64_array_scalar` input is `[rod_length, price_for_length_1, ..., price_for_length_n]`, with exactly one price per length. Rod length is 1 through 30 and each price is a positive integer from 1 through 1,000. Return the maximum revenue as a signed 64-bit integer. Malformed input or values outside these bounds return `-1`. The result is at most 30,000, within the pinned C++ implementation's `int16_t` return range.

The positive-price and nonempty bounds give a shared domain across the source variants. Rust takes a price slice and derives the rod length from its length; Python exposes naive, top-down, and bottom-up functions and this benchmark follows `bottom_up_cut_rod`; Java and JavaScript take both the price array and length. Java rejects an empty price array, so zero-length rods are excluded. JavaScript initializes its candidate maximum with `Number.MIN_VALUE`, which differs for nonpositive-only price arrays, so prices are restricted to positive values.

The C++ candidates `cut_rod.cpp` in TheAlgorithms/C-Plus-Plus and TheAlgorithms/C-Plus-Plus-1, and the Java, JavaScript, Python, Kotlin, and Rust candidates, all use the same unbounded first-cut recurrence on this bounded domain. The Go `rodcutting` candidate uses one-based prices with an unused zero slot; the shared contract's price array can be adapted by prepending that slot. These are mapped to this canonical benchmark as semantic aliases. The C++ implementation narrows its final result to `int16_t`; the contract bound keeps it in range. JavaScript initializes its maximum with `Number.MIN_VALUE`, but positive prices ensure the recurrence agrees here.

Pinned source paths: [C-Plus-Plus `cut_rod.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/cut_rod.cpp), [C-Plus-Plus-1 `cut_rod.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/cut_rod.cpp), [Java `RodCutting.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/RodCutting.java), [JavaScript `RodCutting.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/RodCutting.js), [Python `rod_cutting.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/rod_cutting.py), [Kotlin `RodCuttingProblem.kt`](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/RodCuttingProblem.kt), [Rust `rod_cutting.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/rod_cutting.rs), and [Go `rodcutting.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/rodcutting.go).

[`workload.json`](workload.json) includes the classic four-price example, the pinned C++ examples at lengths 8 and 30, a case where cutting beats selling the whole rod, and invalid packed shapes and prices. The pinned [C++ source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/cut_rod.cpp) is at commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rod_cutting.c`](../../../c/r/rod_cutting.c) |
| C3 | [`c3/r/rod_cutting.c3`](../../../c3/r/rod_cutting.c3) |
| C++ | [`cpp/r/rod_cutting.cpp`](../../../cpp/r/rod_cutting.cpp) |
| Elisa | [`elisa/r/rod_cutting.elisa`](../../../elisa/r/rod_cutting.elisa) |
| Nim | [`nim/r/rod_cutting.nim`](../../../nim/r/rod_cutting.nim) |
| Odin | [`odin/r/rod_cutting.odin`](../../../odin/r/rod_cutting.odin) |
| Rust | [`rust/r/rod_cutting.rs`](../../../rust/r/rod_cutting.rs) |
| V | [`v/r/rod_cutting.v`](../../../v/r/rod_cutting.v) |
| Zig | [`zig/r/rod_cutting.zig`](../../../zig/r/rod_cutting.zig) |
