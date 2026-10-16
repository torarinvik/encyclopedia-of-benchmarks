# Mode of a bounded integer array

Return the value that occurs most often in an integer array when exactly one value has the greatest frequency.

## Contract

- The `i64_array_scalar` ABI receives 1 through 4,096 signed 64-bit integers.
- Every value must be in `[0, 255]`.
- Return the unique mode as a signed 64-bit integer.
- Return `-1` for an empty or overlong array, an out-of-range value, or a tie for greatest frequency.

The pinned Go function returns one mode and leaves ties unspecified because it iterates over a map. The pinned Java function returns every tied mode, and the PHP function also returns mode values as a collection. This benchmark uses only inputs with a unique mode; ties are outside the source algorithms' common scalar result contract and are assigned the benchmark sentinel `-1`. Restricting values to one byte keeps the workload bounded and permits a fixed 256-bin frequency table.

[`workload.json`](workload.json) includes singleton, repeated, boundary, invalid, tied, empty, and maximum-length inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/mode.c`](../../../c/m/mode.c) |
| C3 | [`c3/m/mode.c3`](../../../c3/m/mode.c3) |
| C++ | [`cpp/m/mode.cpp`](../../../cpp/m/mode.cpp) |
| Elisa | [`elisa/m/mode.elisa`](../../../elisa/m/mode.elisa) |
| Nim | [`nim/m/mode.nim`](../../../nim/m/mode.nim) |
| Odin | [`odin/m/mode.odin`](../../../odin/m/mode.odin) |
| Rust | [`rust/m/mode.rs`](../../../rust/m/mode.rs) |
| V | [`v/m/mode.v`](../../../v/m/mode.v) |
| Zig | [`zig/m/mode.zig`](../../../zig/m/mode.zig) |

## Pinned source variants

- [Go `math/mode.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/mode.go)
- [Java `Mode.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Mode.java)
- [PHP `Maths/Mode.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/Mode.php)
